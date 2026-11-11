
package com.housesecurity.ia;

import com.housesecurity.ia.service.GroqService;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class AnaliseController {

    private final GroqService groqService;

    public AnaliseController(GroqService groqService) {
        this.groqService = groqService;
    }

    @PostMapping(
        value = "/analise",
        consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<Map<String, String>> analisar(
            @RequestParam("arquivo") MultipartFile arquivo) {

        if (arquivo == null || arquivo.isEmpty()) {
            return ResponseEntity.badRequest().body(
                Map.of("mensagem", "Nenhum arquivo foi enviado.")
            );
        }

        String nome = arquivo.getOriginalFilename();

        if (nome == null || !(
                nome.toLowerCase().endsWith(".png")
                || nome.toLowerCase().endsWith(".jpg")
                || nome.toLowerCase().endsWith(".jpeg")
                || nome.toLowerCase().endsWith(".pdf"))) {

            return ResponseEntity.badRequest().body(
                Map.of("mensagem",
                    "Formato não suportado. Envie PNG, JPG ou PDF.")
            );
        }

        String extensao = nome.substring(nome.lastIndexOf("."));

        Path arquivoTemporario = null;

        try {
            arquivoTemporario = Files.createTempFile(
                "planta-", extensao
            );

            arquivo.transferTo(arquivoTemporario);

            String relatorio = groqService.analisarPlanta(
                arquivoTemporario
            );

            return ResponseEntity.ok(
                Map.of("relatorio", relatorio)
            );

        } catch (IOException e) {

            return ResponseEntity.badRequest().body(
                Map.of("mensagem",
                    "Não foi possível processar o arquivo enviado.")
            );

        } catch (IllegalStateException e) {

            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(
                Map.of("mensagem",
                    "Não foi possível obter a análise da inteligência artificial.")
            );

        } finally {

            if (arquivoTemporario != null) {
                try {
                    Files.deleteIfExists(arquivoTemporario);
                } catch (IOException ignored) {
                    // Não interrompe a resposta caso a exclusão falhe.
                }
            }
        }
    }
}
