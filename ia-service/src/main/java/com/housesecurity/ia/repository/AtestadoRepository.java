package com.housesecurity.ia.repository;

import com.housesecurity.ia.model.Atestado;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AtestadoRepository extends JpaRepository<Atestado, Integer> {
    List<Atestado> findAllByOrderByCriacaoDesc();
}