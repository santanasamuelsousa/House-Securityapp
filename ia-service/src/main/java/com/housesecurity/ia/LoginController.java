
package com.housesecurity.ia;

import com.housesecurity.ia.service.LoginService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class LoginController {

    private final LoginService loginService;

    public LoginController(LoginService loginService) {
        this.loginService = loginService;
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, String>> login(
            @RequestBody Map<String, String> dados) {

        String email = dados.get("email");
        String senha = dados.get("senha");

        if (email == null || senha == null ||
                email.isBlank() || senha.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("mensagem",
                            "E-mail e senha são obrigatórios."));
        }

        boolean autenticado =
                loginService.autenticar(email, senha);

        if (!autenticado) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("mensagem",
                            "E-mail ou senha inválidos."));
        }

        return ResponseEntity.ok(
                Map.of("mensagem", "Login realizado com sucesso."));
    }
}
