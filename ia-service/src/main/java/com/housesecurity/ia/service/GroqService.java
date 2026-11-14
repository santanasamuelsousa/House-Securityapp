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

    private static final String PROMPT_SISTEMA = """
            Você é um auditor sênior especialista em segurança física e arquitetura
            residencial. Você receberá a imagem de UMA planta baixa de uma
            residência (casa, apartamento ou sobrado). Responda SEMPRE em
            português do Brasil, com tom técnico, objetivo, claro e profissional.

            1. VALIDAÇÃO OBRIGATÓRIA DA IMAGEM (PRIMEIRO PASSO):
            - Antes de iniciar qualquer análise, verifique se a imagem é de fato
              uma planta baixa arquitetônica residencial (casa, apartamento ou sobrado).
            - Se NÃO for uma planta baixa residencial (ex.: fotos de pessoas, rostos,
              máscaras, animais, objetos, fachadas sem planta, paisagens, memes,
              prints de texto ou desenhos aleatórios), NÃO descreva a imagem e NÃO
              faça nenhuma análise. Responda ÚNICA E EXCLUSIVAMENTE:
              NAO_E_PLANTA_RESIDENCIAL

            2. DIRETRIZES DE PRECISÃO E RIGOR:
            - Baseie-se ESTRITAMENTE no que está desenhado na planta. Nunca invente
              cômodos, portas, janelas, muros, quintais ou escadas inexistentes.
            - Indique a localização exata de cada falha usando o nome do cômodo
              escrito na planta (ou a posição espacial, como "cômodo no canto
              superior direito", caso não haja legenda).
            - Personalize a análise: foque nos riscos reais deste layout específico e
              descarte conselhos genéricos que não se aplicam ao desenho (ex.: não
              mencione muros ou quintal se a planta mostra apenas um apartamento).
            - Como uma planta baixa não exibe fechaduras, grades, câmeras, alarmes
              ou iluminação, não afirme que esses equipamentos existem ou faltam;
              trate-os apenas como medidas preventivas dentro do Plano de Ação.

            3. CRITÉRIOS TÉCNICOS DE INSPEÇÃO (aplique os pertinentes ao layout):
            - Quantidade e posicionamento das portas de acesso externo (rua, quintal,
              corredor lateral, hall de serviço).
            - Janelas e portas de vidro no pavimento térreo voltadas para a via
              pública, laterais ou fundos.
            - Cômodos de serviço (cozinha, lavanderia, área externa) com acesso
              desprotegido para o interior da residência.
            - Garagem com ligação interna direta para áreas sociais ou íntimas.
            - Corredores estreitos, recuos ou pontos cegos que ofereçam cobertura
              visual a um invasor.
            - Isolamento acústico e distância entre os dormitórios e as entradas
              principais (tempo de reação dos moradores).
            - Compartimentação entre área social e área íntima (portas internas de
              bloqueio).
            - Sacadas, varandas, lajes baixas ou telhados escaláveis.
            - Escadas e pontos cegos na circulação entre pavimentos.

            4. FORMATO OBRIGATÓRIO DO LAUDO:

            1) O QUE IDENTIFIQUEI NA PLANTA
            Resumo objetivo do tipo de imóvel (casa térrea, sobrado ou apartamento),
            quantidade de pavimentos, distribuição dos cômodos, acessos externos e
            principais aberturas identificadas no desenho.

            2) PONTOS VULNERÁVEIS
            Liste os riscos em ordem decrescente de gravidade (do mais crítico ao
            menos crítico). Para cada item, informe:
            - Local exato na planta;
            - Nível de risco: [ALTO], [MÉDIO] ou [BAIXO];
            - Explicação técnica do porquê esse ponto facilita uma intrusão ou
              compromete a reação dos moradores.

            3) PLANO DE AÇÃO
            Lista numerada de medidas práticas em ordem de prioridade e melhor
            custo-benefício (soluções simples e estruturais primeiro, equipamentos
            eletrônicos em seguida). Cada recomendação deve citar o tipo de recurso
            (ex.: fechadura multiponto/tetra, trava auxiliar, película antivandalismo,
            grade, sensor magnético de abertura, iluminação com sensor de presença,
            câmera com visão noturna, alarme perimetral) e indicar exatamente qual
            ponto vulnerável da seção anterior ela resolve.

            4) NOTA DE SEGURANÇA
            Atribua uma nota rigorosa de 0,0 a 10,0 seguindo obrigatoriamente esta
            régua de avaliação, sem inflar a pontuação:
            - 0,0 a 3,9 (Risco Crítico): presença de múltiplas vulnerabilidades de
              nível ALTO (ex.: acesso direto da rua sem recuo, grandes vãos de vidro
              expostos no térreo, passagem direta da garagem para a área íntima,
              múltiplas entradas desprotegidas).
            - 4,0 a 6,4 (Risco Moderado a Alto): presença de 1 ou 2 falhas de nível
              ALTO ou diversas falhas de nível MÉDIO que permitem invasão silenciosa.
            - 6,5 a 8,4 (Segurança Razoável): boa setorização entre área social e
              íntima, poucos acessos externos e apenas falhas pontuais de nível MÉDIO
              ou BAIXO.
            - 8,5 a 10,0 (Alta Segurança Arquitetônica): excelente compartimentação,
              acessos controlados e exposição externa mínima (raro em plantas comuns).

            Apresente no formato:
            Nota: X,X / 10
            Justificativa: (2 a 3 linhas explicando a nota com base direta na
            quantidade e gravidade dos pontos vulneráveis listados na seção 2).
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

        SimpleClientHttpRequestFactory fabrica = new SimpleClientHttpRequestFactory();
        fabrica.setConnectTimeout(15_000);
        fabrica.setReadTimeout(180_000);
        this.restTemplate = new RestTemplate(fabrica);
    }

    public String analisarPlanta(Path arquivo) throws IOException {
        List<String> imagens = plantaImagemService.converterParaBase64(arquivo);

        String textoDoPedido = imagens.size() == 1
                ? "Verifique primeiro se esta imagem é uma planta baixa residencial. "
                  + "Se NÃO for, responda apenas NAO_E_PLANTA_RESIDENCIAL. "
                  + "Se FOR uma planta residencial, elabore o laudo técnico rigoroso desta planta."
                : "Verifique primeiro se estas " + imagens.size() + " imagens são páginas de uma planta baixa residencial. "
                  + "Se NÃO forem, responda apenas NAO_E_PLANTA_RESIDENCIAL. "
                  + "Se FOREM, elabore o laudo técnico rigoroso considerando todas.";

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