package com.housesecurity.ia.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "atestado")
public class Atestado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_atestado")
    private Integer idAtestado;

    @JsonIgnore
    @Column(name = "url_arquivo", columnDefinition = "bytea")
    private byte[] urlArquivo;

    @Column(name = "analise_ia", columnDefinition = "TEXT")
    private String analiseIa;

    @Column(name = "criacao")
    private LocalDateTime criacao;

    @Column(name = "id_cliente")
    private Integer idCliente;

    public Atestado() {
    }

    public Integer getIdAtestado() {
        return idAtestado;
    }

    public void setIdAtestado(Integer idAtestado) {
        this.idAtestado = idAtestado;
    }

    public byte[] getUrlArquivo() {
        return urlArquivo;
    }

    public void setUrlArquivo(byte[] urlArquivo) {
        this.urlArquivo = urlArquivo;
    }

    public String getAnaliseIa() {
        return analiseIa;
    }

    public void setAnaliseIa(String analiseIa) {
        this.analiseIa = analiseIa;
    }

    public LocalDateTime getCriacao() {
        return criacao;
    }

    public void setCriacao(LocalDateTime criacao) {
        this.criacao = criacao;
    }

    public Integer getIdCliente() {
        return idCliente;
    }

    public void setIdCliente(Integer idCliente) {
        this.idCliente = idCliente;
    }
}