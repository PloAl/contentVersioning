--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.9
-- Dumped by pg_dump version 10.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: save_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.save_version() RETURNS trigger
    LANGUAGE plpgsql LEAKPROOF
    AS $$    BEGIN
		INSERT INTO versions (stamptime,userid,typeid,refid,objectstr) VALUES(OLD.changestamp,OLD.userid,MD5(TG_TABLE_NAME)::uuid,OLD.refid,row_to_json(OLD));
		NEW.changestamp	= current_timestamp;
        RETURN NEW;
    END;

$$;


ALTER FUNCTION public.save_version() OWNER TO postgres;

--
-- Name: update_group_users(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_group_users() RETURNS trigger
    LANGUAGE plpgsql LEAKPROOF
    AS $$    BEGIN
		IF (TG_OP = 'INSERT') THEN
			INSERT INTO usersgroup (groupid, userid)
				SELECT * FROM jsonb_populate_recordset(null::usersgroup, NEW.users);
		ELSIF OLD.users != NEW.users THEN
			DELETE FROM usersgroup WHERE groupid = OLD.refid;
			INSERT INTO usersgroup (groupid, userid)
				SELECT * FROM jsonb_populate_recordset(null::usersgroup, NEW.users);
		END IF;	
        RETURN NEW;
    END;

$$;


ALTER FUNCTION public.update_group_users() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: groupscatalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.groupscatalog (
    refid uuid NOT NULL,
    groupname character varying(25) NOT NULL,
    extdescription character varying NOT NULL,
    users jsonb,
    userid uuid NOT NULL,
    changestamp timestamp with time zone NOT NULL
);


ALTER TABLE public.groupscatalog OWNER TO postgres;

--
-- Name: userscatalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.userscatalog (
    refid uuid NOT NULL,
    username character varying(25) NOT NULL,
    extdescription character varying(256) NOT NULL,
    userid uuid NOT NULL,
    changestamp timestamp with time zone NOT NULL
);


ALTER TABLE public.userscatalog OWNER TO postgres;

--
-- Name: usersgroup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usersgroup (
    groupid uuid NOT NULL,
    userid uuid NOT NULL
);


ALTER TABLE public.usersgroup OWNER TO postgres;

--
-- Name: versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versions (
    stamptime timestamp with time zone NOT NULL,
    userid uuid NOT NULL,
    typeid uuid NOT NULL,
    refid uuid NOT NULL,
    objectstr jsonb NOT NULL
);


ALTER TABLE public.versions OWNER TO postgres;

--
-- Name: groupscatalog groupscatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groupscatalog
    ADD CONSTRAINT groupscatalog_pkey PRIMARY KEY (refid);


--
-- Name: userscatalog userscatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.userscatalog
    ADD CONSTRAINT userscatalog_pkey PRIMARY KEY (refid);


--
-- Name: usersgroup_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX usersgroup_id ON public.usersgroup USING btree (groupid, userid);

ALTER TABLE public.usersgroup CLUSTER ON usersgroup_id;


--
-- Name: userscatalog savevers; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER savevers BEFORE UPDATE ON public.userscatalog FOR EACH ROW EXECUTE PROCEDURE public.save_version();


--
-- Name: groupscatalog savevers; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER savevers BEFORE UPDATE ON public.groupscatalog FOR EACH ROW EXECUTE PROCEDURE public.save_version();


--
-- Name: groupscatalog update_users; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users BEFORE INSERT OR UPDATE ON public.groupscatalog FOR EACH ROW EXECUTE PROCEDURE public.update_group_users();


--
-- PostgreSQL database dump complete
--

