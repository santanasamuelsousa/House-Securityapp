package com.housesecurity.ia;

import com.housesecurity.ia.model.Cliente;
import com.housesecurity.ia.service.LoginService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api")
public class LoginController {

    private final LoginService loginService;

    public LoginController(LoginService loginService) {
        this.loginService = loginService;
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(
            @RequestBody Map<String, String> dados) {

        String email = dados.get("email");
        String senha = dados.get("senha");

        if (email == null || senha == null ||
                email.isBlank() || senha.isBlank()) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "mensagem",
                            "E-mail e senha são obrigatórios."
                    ));
        }

        Optional<Cliente> resultado =
                loginService.autenticar(email, senha);

        if (resultado.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of(
                            "mensagem",
                            "E-mail ou senha inválidos."
                    ));
        }

        Cliente cliente = resultado.get();

        return ResponseEntity.ok(
                Map.of(
                        "mensagem", "Login realizado com sucesso.",
                        "idCliente", cliente.getIdCliente(),
                        "nome", cliente.getNome(),
                        "email", cliente.getEmail()
                )
        );
    }
}