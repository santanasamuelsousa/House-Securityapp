--
-- PostgreSQL database dump
--

\restrict PocIjgEz5wW4Y6EKfJxSjOQbSiBBmMVezBDQvFapRm4EcU3lbe0EyTAzBItaMzP

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: atestado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.atestado (
    id_atestado integer NOT NULL,
    url_arquivo text NOT NULL,
    analise_ia text NOT NULL,
    criacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_cliente integer
);


ALTER TABLE public.atestado OWNER TO postgres;

--
-- Name: atestado_id_atestado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.atestado ALTER COLUMN id_atestado ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.atestado_id_atestado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    id_cliente integer NOT NULL,
    cpf character varying(20) NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    senha character varying(255) NOT NULL,
    cep character varying(10) NOT NULL,
    rua character varying(150) NOT NULL,
    numero character varying(4) NOT NULL,
    telefone character varying(15) NOT NULL
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.cliente ALTER COLUMN id_cliente ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cliente_id_cliente_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: produtoatestado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produtoatestado (
    id_itematestado integer NOT NULL,
    id_atestado integer,
    id_produto integer,
    quantidade integer
);


ALTER TABLE public.produtoatestado OWNER TO postgres;

--
-- Name: produtoatestado_id_itematestado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.produtoatestado ALTER COLUMN id_itematestado ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.produtoatestado_id_itematestado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: produtos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produtos (
    id_produto integer NOT NULL,
    categoria character varying(100) NOT NULL,
    marca character varying(60) NOT NULL,
    preco numeric(10,2) NOT NULL
);


ALTER TABLE public.produtos OWNER TO postgres;

--
-- Name: produtos_id_produto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.produtos ALTER COLUMN id_produto ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.produtos_id_produto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: atestado atestado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atestado
    ADD CONSTRAINT atestado_pkey PRIMARY KEY (id_atestado);


--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (id_cliente);


--
-- Name: produtoatestado produtoatestado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtoatestado
    ADD CONSTRAINT produtoatestado_pkey PRIMARY KEY (id_itematestado);


--
-- Name: produtos produtos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_pkey PRIMARY KEY (id_produto);


--
-- Name: atestado atestado_id_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atestado
    ADD CONSTRAINT atestado_id_cliente_fkey FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- Name: produtoatestado produtoatestado_id_atestado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtoatestado
    ADD CONSTRAINT produtoatestado_id_atestado_fkey FOREIGN KEY (id_atestado) REFERENCES public.atestado(id_atestado);


--
-- Name: produtoatestado produtoatestado_id_produto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtoatestado
    ADD CONSTRAINT produtoatestado_id_produto_fkey FOREIGN KEY (id_produto) REFERENCES public.produtos(id_produto);


--
-- PostgreSQL database dump complete
--

\unrestrict PocIjgEz5wW4Y6EKfJxSjOQbSiBBmMVezBDQvFapRm4EcU3lbe0EyTAzBItaMzP

