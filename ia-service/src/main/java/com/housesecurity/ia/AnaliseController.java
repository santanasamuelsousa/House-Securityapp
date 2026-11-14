package com.housesecurity.ia;

import com.housesecurity.ia.model.Atestado;
import com.housesecurity.ia.repository.AtestadoRepository;
import com.housesecurity.ia.service.GroqService;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class AnaliseController {

    private final GroqService groqService;
    private final AtestadoRepository atestadoRepository;

    public AnaliseController(
            GroqService groqService,
            AtestadoRepository atestadoRepository) {
        this.groqService = groqService;
        this.atestadoRepository = atestadoRepository;
    }

    @PostMapping(
        value = "/analise",
        consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity analisar(
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

            String verificacao = relatorio.trim().toUpperCase();
            if (verificacao.contains("NAO_E_PLANTA_RESIDENCIAL")
                    || verificacao.startsWith("NÃO É UMA PLANTA RESIDENCIAL")) {
                return ResponseEntity.badRequest().body(
                    Map.of("mensagem",
                        "Isto não é uma planta residencial. Por favor, troque o arquivo por uma planta residencial válida e tente novamente.")
                );
            }

            Atestado registro = new Atestado();
            registro.setUrlArquivo(Files.readAllBytes(arquivoTemporario));
            registro.setAnaliseIa(relatorio);
            registro.setCriacao(LocalDateTime.now());
            atestadoRepository.save(registro);

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
                    "Não foi possível obter a análise, tente novamente em alguns instantes.")
            );

        } finally {

            if (arquivoTemporario != null) {
                try {
                    Files.deleteIfExists(arquivoTemporario);
                } catch (IOException ignored) {
                }
            }
        }
    }

    @GetMapping("/analises")
    public ResponseEntity listarAnalises() {
        return ResponseEntity.ok(
            atestadoRepository.findAllByOrderByCriacaoDesc()
        );
    }

    @DeleteMapping("/analises/{id}")
    public ResponseEntity excluirAnalise(@PathVariable Integer id) {
        if (!atestadoRepository.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                Map.of("mensagem", "Relatório não encontrado.")
            );
        }

        atestadoRepository.deleteById(id);
        return ResponseEntity.ok(
            Map.of("mensagem", "Relatório excluído com sucesso.")
        );
    }
}