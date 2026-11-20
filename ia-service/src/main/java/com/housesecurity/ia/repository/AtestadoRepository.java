
package com.housesecurity.ia.repository;

import com.housesecurity.ia.model.Atestado;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AtestadoRepository extends JpaRepository<Atestado, Integer> {

    List<Atestado> findAllByIdClienteOrderByCriacaoDesc(Integer idCliente);

    Optional<Atestado> findByIdAtestadoAndIdCliente(Integer idAtestado, Integer idCliente);
}
