--
-- PostgreSQL database dump
--

-- Dumped from database version 14.16 (Homebrew)
-- Dumped by pg_dump version 14.16 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
-- Name: analyses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analyses (
    id uuid NOT NULL,
    file_path character varying(255) NOT NULL,
    language character varying(255) NOT NULL,
    content text NOT NULL,
    focus_areas character varying(255)[] DEFAULT ARRAY['performance'::character varying, 'maintainability'::character varying],
    severity_threshold character varying(255) DEFAULT 'medium'::character varying,
    completed_at timestamp without time zone,
    is_multi_file boolean DEFAULT false,
    project_id uuid,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: analysis_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analysis_relationships (
    id uuid NOT NULL,
    source_analysis_id uuid NOT NULL,
    target_analysis_id uuid NOT NULL,
    relationship_type character varying(255) NOT NULL,
    details jsonb DEFAULT '{}'::jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: evaluations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evaluations (
    id uuid NOT NULL,
    metrics jsonb NOT NULL,
    success boolean NOT NULL,
    report text,
    optimization_id uuid NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: experiments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiments (
    id uuid NOT NULL,
    setup_data jsonb,
    results jsonb,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    experiment_path character varying(255),
    evaluation_id uuid NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: opportunities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.opportunities (
    id uuid NOT NULL,
    location character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    description text NOT NULL,
    severity character varying(255) NOT NULL,
    rationale text,
    suggested_change text,
    analysis_id uuid NOT NULL,
    cross_file_references jsonb[] DEFAULT ARRAY[]::jsonb[],
    scope character varying(255) DEFAULT 'single_file'::character varying,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: optimizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.optimizations (
    id uuid NOT NULL,
    strategy character varying(255) NOT NULL,
    original_code text NOT NULL,
    optimized_code text NOT NULL,
    explanation text,
    status character varying(255) DEFAULT 'pending'::character varying,
    opportunity_id uuid NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    base_path character varying(255) NOT NULL,
    description text,
    settings jsonb DEFAULT '{}'::jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: analyses analyses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analyses
    ADD CONSTRAINT analyses_pkey PRIMARY KEY (id);


--
-- Name: analysis_relationships analysis_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis_relationships
    ADD CONSTRAINT analysis_relationships_pkey PRIMARY KEY (id);


--
-- Name: evaluations evaluations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluations
    ADD CONSTRAINT evaluations_pkey PRIMARY KEY (id);


--
-- Name: experiments experiments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_pkey PRIMARY KEY (id);


--
-- Name: opportunities opportunities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opportunities
    ADD CONSTRAINT opportunities_pkey PRIMARY KEY (id);


--
-- Name: optimizations optimizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.optimizations
    ADD CONSTRAINT optimizations_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: analyses_project_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX analyses_project_id_index ON public.analyses USING btree (project_id);


--
-- Name: analysis_relationship_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX analysis_relationship_unique_index ON public.analysis_relationships USING btree (source_analysis_id, target_analysis_id, relationship_type);


--
-- Name: analysis_relationships_source_analysis_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX analysis_relationships_source_analysis_id_index ON public.analysis_relationships USING btree (source_analysis_id);


--
-- Name: analysis_relationships_target_analysis_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX analysis_relationships_target_analysis_id_index ON public.analysis_relationships USING btree (target_analysis_id);


--
-- Name: evaluations_optimization_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX evaluations_optimization_id_index ON public.evaluations USING btree (optimization_id);


--
-- Name: experiments_evaluation_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX experiments_evaluation_id_index ON public.experiments USING btree (evaluation_id);


--
-- Name: opportunities_analysis_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX opportunities_analysis_id_index ON public.opportunities USING btree (analysis_id);


--
-- Name: optimizations_opportunity_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX optimizations_opportunity_id_index ON public.optimizations USING btree (opportunity_id);


--
-- Name: analyses analyses_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analyses
    ADD CONSTRAINT analyses_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: analysis_relationships analysis_relationships_source_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis_relationships
    ADD CONSTRAINT analysis_relationships_source_analysis_id_fkey FOREIGN KEY (source_analysis_id) REFERENCES public.analyses(id) ON DELETE CASCADE;


--
-- Name: analysis_relationships analysis_relationships_target_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis_relationships
    ADD CONSTRAINT analysis_relationships_target_analysis_id_fkey FOREIGN KEY (target_analysis_id) REFERENCES public.analyses(id) ON DELETE CASCADE;


--
-- Name: evaluations evaluations_optimization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluations
    ADD CONSTRAINT evaluations_optimization_id_fkey FOREIGN KEY (optimization_id) REFERENCES public.optimizations(id) ON DELETE CASCADE;


--
-- Name: experiments experiments_evaluation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_evaluation_id_fkey FOREIGN KEY (evaluation_id) REFERENCES public.evaluations(id) ON DELETE CASCADE;


--
-- Name: opportunities opportunities_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opportunities
    ADD CONSTRAINT opportunities_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES public.analyses(id) ON DELETE CASCADE;


--
-- Name: optimizations optimizations_opportunity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.optimizations
    ADD CONSTRAINT optimizations_opportunity_id_fkey FOREIGN KEY (opportunity_id) REFERENCES public.opportunities(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20250313000001);
