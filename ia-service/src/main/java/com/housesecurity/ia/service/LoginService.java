
package com.housesecurity.ia.service;

import com.housesecurity.ia.model.Cliente;
import com.housesecurity.ia.repository.ClienteRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class LoginService {

    private final ClienteRepository clienteRepository;
    private final PasswordEncoder passwordEncoder;

    public LoginService(
            ClienteRepository clienteRepository,
            PasswordEncoder passwordEncoder) {

        this.clienteRepository = clienteRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public boolean autenticar(String email, String senha) {
        Optional<Cliente> resultado =
                clienteRepository.findByEmail(email);

        if (resultado.isEmpty()) {
            return false;
        }

        Cliente cliente = resultado.get();

        return passwordEncoder.matches(
                senha,
                cliente.getSenha()
        );
    }
}
