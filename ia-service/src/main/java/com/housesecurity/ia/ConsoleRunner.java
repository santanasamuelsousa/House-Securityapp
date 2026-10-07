package com.housesecurity.ia;

import com.housesecurity.ia.service.GroqService;
import com.housesecurity.ia.service.PlantaImagemService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

@Component
public class ConsoleRunner implements CommandLineRunner {

    private static final Path PASTA_PLANTAS = Path.of("plantas");

    private final GroqService groqService;

    public ConsoleRunner(GroqService groqService) {
        this.groqService = groqService;
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println("==============================================");
        System.out.println("   HOUSE SECURITY - Diagnóstico com IA (Groq)");
        System.out.println("==============================================");

        List<Path> plantas = descobrirPlantas(args);

        if (plantas.isEmpty()) {
            System.out.println("Nenhuma planta encontrada.");
            System.out.println("Coloque arquivos PNG, JPG ou PDF na pasta 'plantas' "
                    + "(na raiz do projeto) e rode de novo.");
            return;
        }

        for (Path planta : plantas) {
            System.out.println();
            System.out.println(">>> PLANTA: " + planta.getFileName());
            System.out.println("Aguarde, a IA está analisando...\n");

            try {
                String relatorio = groqService.analisarPlanta(planta);

                System.out.println("-------------- RELATÓRIO DA IA --------------");
                System.out.println(relatorio);
                System.out.println("---------------------------------------------");

            } catch (Exception erro) {
                System.err.println("[ERRO] Não foi possível analisar "
                        + planta.getFileName() + ": " + erro.getMessage());
            }
        }
    }

    /**
     * Se você passou caminhos como argumento, usa eles.
     * Senão, usa todos os arquivos suportados da pasta "plantas".
     */
    private List<Path> descobrirPlantas(String[] args) throws Exception {
        List<Path> plantas = new ArrayList<>();

        if (args.length > 0) {
            for (String argumento : args) {
                Path caminho = Path.of(argumento);
                if (!Files.exists(caminho)) {
                    System.err.println("Arquivo não encontrado: " + caminho.toAbsolutePath());
                } else if (!PlantaImagemService.formatoSuportado(caminho)) {
                    System.err.println("Formato não suportado (use PNG, JPG ou PDF): " + caminho);
                } else {
                    plantas.add(caminho);
                }
            }
        } else if (Files.isDirectory(PASTA_PLANTAS)) {
            try (Stream<Path> arquivos = Files.list(PASTA_PLANTAS)) {
                arquivos.filter(PlantaImagemService::formatoSuportado)
                        .sorted()
                        .forEach(plantas::add);
            }
        }
        return plantas;
    }
}