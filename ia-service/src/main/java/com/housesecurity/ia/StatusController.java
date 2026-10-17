package com.housesecurity.ia;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class StatusController {

    @GetMapping("/api/status")
    public String status() {
        return "House Security API funcionando!";
    }
}