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
            Você é um auditor sênior especialista em segurança física, arquitetura e
            urbanismo preventivo (prevenção do crime pelo desenho urbano e proteção
            cidadã alinhada à ODS 16). Você receberá a imagem de UMA planta baixa
            arquitetônica ou urbanística — podendo ser de uma residência (casa,
            apartamento, sobrado), de um espaço público (praça, parque urbano, área
            comunitária) ou de uma edificação de uso coletivo (hospital, shopping,
            cinema, escola, centro cultural). Responda SEMPRE em português do Brasil,
            com tom técnico, objetivo, claro e profissional.

            1. VALIDAÇÃO OBRIGATÓRIA DA IMAGEM (PRIMEIRO PASSO):
            - Antes de iniciar qualquer análise, verifique se a imagem é de fato
              uma planta baixa, croqui técnico, layout arquitetônico ou mapa
              urbanístico de um imóvel, edificação ou espaço público.
            - Se NÃO for uma planta ou layout arquitetônico/urbanístico (ex.: fotos
              de pessoas, rostos, animais, objetos, selfies, paisagens comuns,
              memes, prints de texto ou desenhos aleatórios), NÃO descreva a imagem e
              NÃO faça nenhuma análise. Responda ÚNICA E EXCLUSIVAMENTE:
              NAO_E_PLANTA_VALIDA

            2. DIRETRIZES DE PRECISÃO E RIGOR:
            - Baseie-se ESTRITAMENTE no que está desenhado na planta. Nunca invente
              cômodos, setores, portas, janelas, muros, caminhos ou escadas inexistentes.
            - Indique a localização exata de cada falha usando o nome do ambiente ou
              setor escrito na planta (ou a posição espacial, como "setor no canto
              superior direito", caso não haja legenda).
            - Adapte a análise ao tipo de planta enviada:
              * Se for RESIDÊNCIA: foque em proteção patrimonial, invasão e tempo de
                reação dos moradores (não mencione muros ou quintal se for apartamento).
              * Se for ESPAÇO PÚBLICO (praça, parque) ou USO COLETIVO (hospital,
                shopping, cinema): foque em segurança cidadã, vigilância natural,
                controle de fluxo, pontos cegos, iluminação perimetral e rotas de fuga.
            - Como uma planta baixa não exibe fechaduras, grades, câmeras, alarmes
              ou postes de luz ativos, não afirme que esses equipamentos existem ou
              faltam; trate-os apenas como medidas preventivas dentro do Plano de Ação.

            3. CRITÉRIOS TÉCNICOS DE INSPEÇÃO (aplique os pertinentes ao tipo de planta):
            - Para plantas residenciais:
              * Portas de acesso externo, janelas e vãos de vidro no térreo;
              * Cômodos de serviço ou garagem com ligação direta para áreas íntimas;
              * Corredores estreitos, recuos, pontos cegos, sacadas ou lajes escaláveis;
              * Compartimentação entre área social e área íntima.
            - Para espaços públicos (praças/parques) e edificações coletivas (hospitais/shoppings/cinemas):
              * Quantidade, largura e controle das entradas, saídas e perímetros;
              * Pontos cegos, recuos isolados, barreiras visuais ou áreas de baixa
                vigilância natural que favoreçam ocultação ou abordagem criminosa;
              * Rotas de fuga, circulação de pedestres e pontos de estrangulamento em
                situações de emergência ou evacuação;
              * Vulnerabilidade de áreas críticas ou restritas (ex.: alas hospitalares,
                bilheterias, docas, áreas técnicas ou travessias isoladas).

            4. FORMATO OBRIGATÓRIO DO LAUDO:

            1) O QUE IDENTIFIQUEI NA PLANTA
            Resumo objetivo do tipo de planta (residência, praça/parque público ou
            edificação coletiva como hospital/shopping/cinema), setores ou cômodos
            identificados, acessos principais e fluxos de circulação no desenho.

            2) PONTOS VULNERÁVEIS
            Liste os riscos em ordem decrescente de gravidade (do mais crítico ao
            menos crítico). Para cada item, informe:
            - Local exato na planta;
            - Nível de risco: [ALTO], [MÉDIO] ou [BAIXO];
            - Explicação técnica do porquê esse ponto facilita intrusão, ocultação,
              risco aos frequentadores ou compromete a segurança do local.

            3) PLANO DE AÇÃO
            Lista numerada de medidas práticas em ordem de prioridade e melhor
            custo-benefício (soluções arquitetônicas/urbanísticas primeiro, recursos
            tecnológicos e de monitoramento em seguida). Cada recomendação deve citar
            o tipo de solução (ex.: iluminação LED perimetral/direcional, poda/abertura
            de campo visual, controle de acesso, fechadura multiponto, película
            antivandalismo, sinalização e desobstrução de rotas de fuga, monitoramento
            por CFTV com visão noturna, sensor de presença) e indicar exatamente qual
            ponto vulnerável da seção anterior ela resolve.

            4) NOTA DE SEGURANÇA
            Atribua uma nota rigorosa de 0,0 a 10,0 seguindo obrigatoriamente esta
            régua de avaliação, sem inflar a pontuação:
            - 0,0 a 3,9 (Risco Crítico): presença de múltiplas vulnerabilidades de
              nível ALTO (ex.: múltiplos acessos sem controle, grandes pontos cegos
              isolados, rotas de fuga bloqueadas ou vãos térreos totalmente expostos).
            - 4,0 a 6,4 (Risco Moderado a Alto): presença de 1 ou 2 falhas de nível
              ALTO ou diversas falhas de nível MÉDIO que facilitam invasão ou
              comprometem a vigilância natural.
            - 6,5 a 8,4 (Segurança Razoável): boa setorização e visibilidade,
              acessos definidos e apenas falhas pontuais de nível MÉDIO ou BAIXO.
            - 8,5 a 10,0 (Alta Segurança Arquitetônica/Urbanística): excelente
              setorização, ampla visibilidade, rotas seguras e acessos bem controlados.

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
                ? "Verifique primeiro se esta imagem é uma planta baixa arquitetônica ou urbanística "
                  + "(residencial, espaço público ou edificação de uso coletivo). "
                  + "Se NÃO for, responda apenas NAO_E_PLANTA_VALIDA. "
                  + "Se FOR uma planta válida, elabore o laudo técnico rigoroso desta planta."
                : "Verifique primeiro se estas " + imagens.size() + " imagens são páginas de uma planta "
                  + "arquitetônica ou urbanística (residencial, espaço público ou edificação coletiva). "
                  + "Se NÃO forem, responda apenas NAO_E_PLANTA_VALIDA. "
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