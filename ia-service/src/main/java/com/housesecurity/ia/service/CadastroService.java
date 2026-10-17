
package com.housesecurity.ia.service;

import com.housesecurity.ia.model.Cliente;
import com.housesecurity.ia.repository.ClienteRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class CadastroService {

    private final ClienteRepository clienteRepository;
    private final PasswordEncoder passwordEncoder;

    public CadastroService(
            ClienteRepository clienteRepository,
            PasswordEncoder passwordEncoder) {

        this.clienteRepository = clienteRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public Cliente cadastrar(Cliente cliente) {
        if (clienteRepository.findByEmail(cliente.getEmail()).isPresent()) {
            throw new IllegalArgumentException(
                    "Este e-mail já está cadastrado."
            );
        }

        cliente.setSenha(
                passwordEncoder.encode(cliente.getSenha())
        );

        return clienteRepository.save(cliente);
    }
}
