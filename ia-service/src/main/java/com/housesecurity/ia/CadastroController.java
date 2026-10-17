
package com.housesecurity.ia;

import com.housesecurity.ia.model.Cliente;
import com.housesecurity.ia.service.CadastroService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class CadastroController {

    private final CadastroService cadastroService;

    public CadastroController(CadastroService cadastroService) {
        this.cadastroService = cadastroService;
    }

    @PostMapping("/cadastro")
    public ResponseEntity<Map<String, String>> cadastrar(
            @RequestBody Cliente cliente) {

        if (cliente.getNome() == null || cliente.getNome().isBlank()
                || cliente.getEmail() == null || cliente.getEmail().isBlank()
                || cliente.getSenha() == null || cliente.getSenha().isBlank()) {

            return ResponseEntity.badRequest().body(
                    Map.of("mensagem",
                            "Nome, e-mail e senha são obrigatórios.")
            );
        }

        try {
            cadastroService.cadastrar(cliente);

            return ResponseEntity.status(HttpStatus.CREATED).body(
                    Map.of("mensagem", "Cadastro realizado com sucesso.")
            );

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(
                    Map.of("mensagem", e.getMessage())
            );
        }
    }
}
