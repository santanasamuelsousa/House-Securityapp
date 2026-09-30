package com.housesecurity.ia.service;

import com.housesecurity.ia.dto.ChatRequest;
import com.housesecurity.ia.dto.ChatRequest.Message;
import com.housesecurity.ia.dto.ChatResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class GroqService {

    // As "regras do jogo" da IA. Foram escritas para forçar uma análise
    // específica da planta enviada, em vez de conselhos genéricos.
    private static final String PROMPT_SISTEMA = """
            Você é um consultor especialista em segurança residencial.
            Você vai receber a imagem de UMA planta baixa de uma residência
            (casa ou apartamento). Responda SEMPRE em português do Brasil,
            com linguagem simples.

            REGRAS IMPORTANTES:
            - Analise SOMENTE o que você realmente enxerga nesta planta.
              Nunca invente cômodos, portas, janelas, muros ou escadas.
            - Se a imagem NÃO for uma planta de residência, responda apenas:
              "NÃO É UMA PLANTA RESIDENCIAL: " seguido do motivo. Nada mais.
            - Sempre diga ONDE está cada problema, usando o nome do cômodo
              escrito na planta (ou a posição, como "cômodo no canto superior
              direito", se não houver nome).
            - Cada planta é única: dê ênfase ao que é DIFERENTE e PROBLEMÁTICO
              nesta planta. Não repita conselhos genéricos que não se aplicam a
              ela (exemplo: não fale de muro se a planta não mostra quintal).
            - Uma planta NÃO mostra iluminação, altura de muro, tipo de
              fechadura, câmeras ou grades. Não afirme isso como fato. Coloque
              esses itens na seção "A CONFIRMAR NO LOCAL".

            O QUE OBSERVAR (use apenas o que se aplicar a esta planta):
            - Quantas portas dão para fora e para onde (rua, quintal, área lateral)
            - Janelas e portas de vidro no térreo voltadas para rua, laterais ou fundos
            - Cômodos com acesso direto ao exterior (cozinha, lavanderia, área de serviço)
            - Garagem com passagem interna para a casa
            - Corredores laterais ou cantos escondidos, que dão cobertura a invasores
            - Distância entre os quartos e as entradas (quem escuta um invasor?)
            - Cômodos sem janela, bons para guardar objetos de valor
            - Sacadas, varandas, lajes ou telhados que podem ser alcançados
            - Em apartamento: porta de entrada, sacada, janelas de serviço, andar
            - Escadas e pontos cegos entre andares

            FORMATO OBRIGATÓRIO DA RESPOSTA:

            1) O QUE IDENTIFIQUEI NA PLANTA
            (tipo de imóvel, número de pavimentos, lista dos cômodos, entradas e
            aberturas que você vê)

            2) PONTOS VULNERÁVEIS
            (lista do mais grave ao menos grave. Para cada um: local exato,
            POR QUE é vulnerável nesta planta e nível BAIXO, MÉDIO ou ALTO)

            3) A CONFIRMAR NO LOCAL
            (o que a planta não permite saber e o morador deve verificar)

            4) PLANO DE AÇÃO
            (passos práticos na ordem de prioridade, soluções baratas primeiro,
            citando o tipo de produto: câmera, sensor de presença, fechadura
            reforçada, iluminação com sensor, grade, película, alarme etc.,
            sempre ligado ao ponto vulnerável que resolve)

            5) NOTA DE SEGURANÇA
            (de 0 a 10, com uma linha justificando)
            """;

    private final RestTemplate restTemplate;
    private final PlantaImagemService plantaImagemService;

    @Value("${groq.api.key}")
    private String apiKey;

    @Value("${groq.api.url}")
    private String apiUrl;

    @Value("${groq.model.vision}")
    private String modeloVisao;

    @Value("${groq.temperature}")
    private double temperatura;

    @Value("${groq.max-tokens}")
    private int limiteTokens;

    @Value("${groq.reasoning-effort:}")
    private String esforcoRaciocinio;

    @Value("${groq.reasoning-format:}")
    private String formatoRaciocinio;

    public GroqService(PlantaImagemService plantaImagemService) {
        this.plantaImagemService = plantaImagemService;

        // Tempo máximo de espera (a IA "pensa" antes de responder, então damos folga)
        SimpleClientHttpRequestFactory fabrica = new SimpleClientHttpRequestFactory();
        fabrica.setConnectTimeout(15_000);   // 15 segundos para conectar
        fabrica.setReadTimeout(180_000);     // 3 minutos para receber a resposta
        this.restTemplate = new RestTemplate(fabrica);
    }

    /**
     * Analisa uma planta residencial (PNG, JPG ou PDF) e devolve o relatório em texto.
     */
    public String analisarPlanta(Path arquivo) throws IOException {
        // 1) Converte o arquivo em imagens Base64 (PDF vira uma imagem por página)
        List<String> imagens = plantaImagemService.converterParaBase64(arquivo);

        // 2) Monta o pedido: um texto + a(s) imagem(ns)
        String textoDoPedido = imagens.size() == 1
                ? "Analise a segurança da residência desta planta. Seja específico para ESTA planta."
                : "Estas " + imagens.size() + " imagens são páginas da MESMA planta. "
                  + "Analise a segurança da residência considerando todas. "
                  + "Seja específico para ESTA planta.";

        List<Object> conteudo = new ArrayList<>();
        conteudo.add(Map.of("type", "text", "text", textoDoPedido));
        for (String base64 : imagens) {
            conteudo.add(Map.of(
                    "type", "image_url",
                    "image_url", Map.of("url", "data:image/jpeg;base64," + base64)));
        }

        List<Message> mensagens = List.of(
                new Message("system", PROMPT_SISTEMA),
                new Message("user", conteudo)
        );

        ChatRequest requisicao = new ChatRequest(
                modeloVisao,
                mensagens,
                temperatura,
                limiteTokens,
                vazioParaNulo(esforcoRaciocinio),
                vazioParaNulo(formatoRaciocinio)
        );

        return enviar(requisicao);
    }

    private String vazioParaNulo(String valor) {
        return (valor == null || valor.isBlank()) ? null : valor;
    }

    /**
     * Faz a chamada HTTP para a Groq e devolve só o texto da resposta.
     */
    private String enviar(ChatRequest requisicao) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException(
                    "Chave da Groq não encontrada. Defina a variável de ambiente GROQ_API_KEY.");
        }

        HttpHeaders cabecalhos = new HttpHeaders();
        cabecalhos.setContentType(MediaType.APPLICATION_JSON);
        cabecalhos.setBearerAuth(apiKey);

        HttpEntity<ChatRequest> entidade = new HttpEntity<>(requisicao, cabecalhos);

        try {
            ChatResponse resposta = restTemplate.postForObject(apiUrl, entidade, ChatResponse.class);

            if (resposta == null || resposta.choices() == null || resposta.choices().isEmpty()) {
                return "A Groq não devolveu nenhuma resposta.";
            }

            String texto = resposta.choices().get(0).message().content();
            if (texto == null || texto.isBlank()) {
                return "A resposta veio vazia. Tente aumentar groq.max-tokens ou "
                        + "diminuir groq.reasoning-effort no application.properties.";
            }
            return texto;

        } catch (HttpStatusCodeException erro) {
            throw new IllegalStateException(
                    "Erro da Groq (HTTP " + erro.getStatusCode().value() + "): "
                            + erro.getResponseBodyAsString(), erro);
        }
    }
}