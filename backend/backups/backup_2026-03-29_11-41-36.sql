--
-- PostgreSQL database dump
--

\restrict BsPF5ALIHzkyikwpLH3METeCYmzVSN0Pm0UyeOlV3k7aYeeM1Up49KmQ84UaO8d

-- Dumped from database version 13.22
-- Dumped by pg_dump version 13.22

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

--
-- Name: prevent_edit_on_locked_session(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_edit_on_locked_session() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM attendance_sessions s
    WHERE s.id = NEW.session_id
      AND s.is_locked = true
  ) THEN
    RAISE EXCEPTION 'لا يمكن التعديل: الحصة مقفلة';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_edit_on_locked_session() OWNER TO postgres;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_years; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.academic_years (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    school_id bigint NOT NULL
);


ALTER TABLE public.academic_years OWNER TO postgres;

--
-- Name: academic_years_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.academic_years_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.academic_years_id_seq OWNER TO postgres;

--
-- Name: academic_years_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.academic_years_id_seq OWNED BY public.academic_years.id;


--
-- Name: assessment_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assessment_attachments (
    id bigint NOT NULL,
    assessment_id bigint NOT NULL,
    file_url text NOT NULL,
    file_name character varying(255),
    file_type character varying(80),
    file_size bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.assessment_attachments OWNER TO postgres;

--
-- Name: assessment_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assessment_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assessment_attachments_id_seq OWNER TO postgres;

--
-- Name: assessment_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assessment_attachments_id_seq OWNED BY public.assessment_attachments.id;


--
-- Name: assessment_grades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assessment_grades (
    id bigint NOT NULL,
    assessment_id bigint NOT NULL,
    student_id integer NOT NULL,
    status character varying(20) DEFAULT 'missing'::character varying NOT NULL,
    score numeric(6,2),
    feedback text,
    graded_by bigint,
    graded_at timestamp with time zone,
    is_published boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.assessment_grades OWNER TO postgres;

--
-- Name: assessment_grades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assessment_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assessment_grades_id_seq OWNER TO postgres;

--
-- Name: assessment_grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assessment_grades_id_seq OWNED BY public.assessment_grades.id;


--
-- Name: assessment_reopen_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assessment_reopen_requests (
    id bigint NOT NULL,
    assessment_id bigint NOT NULL,
    requested_by_user_id integer NOT NULL,
    reason text NOT NULL,
    status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    admin_note text,
    decided_by_user_id integer,
    decided_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.assessment_reopen_requests OWNER TO postgres;

--
-- Name: assessment_reopen_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assessment_reopen_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assessment_reopen_requests_id_seq OWNER TO postgres;

--
-- Name: assessment_reopen_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assessment_reopen_requests_id_seq OWNED BY public.assessment_reopen_requests.id;


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assessments (
    id bigint NOT NULL,
    teacher_assignment_id bigint NOT NULL,
    type character varying(30) NOT NULL,
    mode character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    max_score numeric(6,2) NOT NULL,
    starts_at timestamp with time zone,
    due_at timestamp with time zone,
    duration_minutes integer,
    late_policy_json jsonb,
    published_at timestamp with time zone,
    closed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    exam_kind character varying(20),
    aggregate_kind character varying(20),
    sequence_no smallint,
    is_system_generated boolean DEFAULT false NOT NULL,
    source_assessment_ids jsonb,
    title_short character varying(255),
    CONSTRAINT chk_assessments_type_detail_consistency CHECK (((((type)::text = 'exam'::text) AND ((exam_kind)::text = ANY ((ARRAY['monthly'::character varying, 'midterm'::character varying, 'final'::character varying])::text[])) AND (aggregate_kind IS NULL) AND ((((exam_kind)::text = 'monthly'::text) AND (COALESCE((sequence_no)::integer, 0) >= 1)) OR (((exam_kind)::text = ANY ((ARRAY['midterm'::character varying, 'final'::character varying])::text[])) AND (sequence_no IS NULL)))) OR (((type)::text = 'aggregate'::text) AND ((aggregate_kind)::text = ANY ((ARRAY['midterm'::character varying, 'final'::character varying])::text[])) AND (exam_kind IS NULL)) OR (((type)::text = ANY ((ARRAY['activity'::character varying, 'classwork'::character varying, 'homework'::character varying, 'project'::character varying, 'oral'::character varying])::text[])) AND (exam_kind IS NULL) AND (aggregate_kind IS NULL)))),
    CONSTRAINT chk_assessments_type_v2 CHECK (((type)::text = ANY ((ARRAY['activity'::character varying, 'classwork'::character varying, 'homework'::character varying, 'exam'::character varying, 'aggregate'::character varying, 'project'::character varying, 'oral'::character varying])::text[])))
);


ALTER TABLE public.assessments OWNER TO postgres;

--
-- Name: COLUMN assessments.exam_kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assessments.exam_kind IS 'يستخدم فقط إذا كان type = exam. القيم: monthly, midterm, final';


--
-- Name: COLUMN assessments.aggregate_kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assessments.aggregate_kind IS 'يستخدم فقط إذا كان type = aggregate. القيم: midterm, final';


--
-- Name: COLUMN assessments.sequence_no; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assessments.sequence_no IS 'رقم التسلسل للاختبار الشهري مثل 1 أو 2';


--
-- Name: COLUMN assessments.is_system_generated; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assessments.is_system_generated IS 'هل أنشأ النظام هذا التقييم تلقائياً';


--
-- Name: COLUMN assessments.source_assessment_ids; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assessments.source_assessment_ids IS 'التقييمات الأصلية التي بُنيت منها المحصلة إن وجدت';


--
-- Name: assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assessments_id_seq OWNER TO postgres;

--
-- Name: assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assessments_id_seq OWNED BY public.assessments.id;


--
-- Name: attendance_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance_entries (
    id bigint NOT NULL,
    session_id bigint NOT NULL,
    student_id integer NOT NULL,
    status text NOT NULL,
    reason_id integer,
    late_minutes integer,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attendance_entries_late_minutes_check CHECK (((late_minutes IS NULL) OR (late_minutes >= 0))),
    CONSTRAINT attendance_entries_status_check CHECK ((status = ANY (ARRAY['present'::text, 'absent'::text, 'late'::text, 'excused'::text]))),
    CONSTRAINT chk_att_late_minutes_logic CHECK ((((status = 'late'::text) AND (late_minutes IS NOT NULL) AND (late_minutes >= 0)) OR ((status <> 'late'::text) AND (late_minutes IS NULL)))),
    CONSTRAINT chk_att_reason_logic CHECK ((((status = ANY (ARRAY['absent'::text, 'excused'::text])) AND ((reason_id IS NULL) OR (reason_id IS NOT NULL))) OR ((status = ANY (ARRAY['present'::text, 'late'::text])) AND (reason_id IS NULL)))),
    CONSTRAINT chk_attendance_entries_status CHECK ((status = ANY (ARRAY['present'::text, 'absent'::text, 'late'::text, 'excused'::text])))
);


ALTER TABLE public.attendance_entries OWNER TO postgres;

--
-- Name: attendance_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_entries_id_seq OWNER TO postgres;

--
-- Name: attendance_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_entries_id_seq OWNED BY public.attendance_entries.id;


--
-- Name: attendance_entry_corrections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance_entry_corrections (
    id bigint NOT NULL,
    session_id bigint NOT NULL,
    student_id integer NOT NULL,
    corrected_status character varying(20) NOT NULL,
    corrected_reason_id integer,
    corrected_late_minutes integer,
    corrected_note text,
    correction_reason text NOT NULL,
    corrected_by_user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    permission_request_id bigint
);


ALTER TABLE public.attendance_entry_corrections OWNER TO postgres;

--
-- Name: attendance_entry_corrections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_entry_corrections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_entry_corrections_id_seq OWNER TO postgres;

--
-- Name: attendance_entry_corrections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_entry_corrections_id_seq OWNED BY public.attendance_entry_corrections.id;


--
-- Name: attendance_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance_reasons (
    id integer NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.attendance_reasons OWNER TO postgres;

--
-- Name: attendance_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_reasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_reasons_id_seq OWNER TO postgres;

--
-- Name: attendance_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_reasons_id_seq OWNED BY public.attendance_reasons.id;


--
-- Name: attendance_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance_sessions (
    id bigint NOT NULL,
    academic_year_id integer NOT NULL,
    term smallint NOT NULL,
    attendance_date date NOT NULL,
    period_id integer NOT NULL,
    section_id integer NOT NULL,
    subject_id integer NOT NULL,
    teacher_id integer NOT NULL,
    created_by integer,
    is_locked boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    locked_at timestamp with time zone,
    locked_by integer,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    lesson_note text,
    source text DEFAULT 'manual'::text NOT NULL,
    notes text,
    stage_id integer,
    grade_id integer,
    duration_seconds integer,
    CONSTRAINT attendance_sessions_term_check CHECK ((term = ANY (ARRAY[1, 2]))),
    CONSTRAINT chk_attendance_sessions_source CHECK ((source = ANY (ARRAY['manual'::text, 'barcode'::text]))),
    CONSTRAINT chk_attendance_sessions_time CHECK (((ended_at IS NULL) OR (started_at IS NULL) OR (ended_at >= started_at)))
);


ALTER TABLE public.attendance_sessions OWNER TO postgres;

--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_sessions_id_seq OWNER TO postgres;

--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_sessions_id_seq OWNED BY public.attendance_sessions.id;


--
-- Name: continuing_batch_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.continuing_batch_items (
    id integer NOT NULL,
    batch_id integer NOT NULL,
    student_id integer NOT NULL,
    from_enrollment_id integer NOT NULL,
    to_grade_id integer,
    to_section_id integer,
    to_enrollment_id integer,
    decision character varying(20) DEFAULT 'promote'::character varying NOT NULL,
    reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT continuing_batch_items_decision_check CHECK (((decision)::text = ANY ((ARRAY['promote'::character varying, 'repeat'::character varying, 'exclude'::character varying])::text[])))
);


ALTER TABLE public.continuing_batch_items OWNER TO postgres;

--
-- Name: continuing_batch_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.continuing_batch_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.continuing_batch_items_id_seq OWNER TO postgres;

--
-- Name: continuing_batch_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.continuing_batch_items_id_seq OWNED BY public.continuing_batch_items.id;


--
-- Name: continuing_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.continuing_batches (
    id integer NOT NULL,
    from_year_id integer NOT NULL,
    to_year_id integer NOT NULL,
    mode character varying(10) DEFAULT 'AUTO'::character varying NOT NULL,
    keep_section boolean DEFAULT true NOT NULL,
    default_section_id integer,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT continuing_batches_mode_check CHECK (((mode)::text = ANY ((ARRAY['AUTO'::character varying, 'KEEP'::character varying, 'MANUAL'::character varying])::text[])))
);


ALTER TABLE public.continuing_batches OWNER TO postgres;

--
-- Name: continuing_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.continuing_batches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.continuing_batches_id_seq OWNER TO postgres;

--
-- Name: continuing_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.continuing_batches_id_seq OWNED BY public.continuing_batches.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    id bigint NOT NULL,
    user_id integer,
    teacher_id integer,
    full_name text NOT NULL,
    phone text NOT NULL,
    job_title text,
    notes text,
    is_teacher boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employees_id_seq OWNER TO postgres;

--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employees_id_seq OWNED BY public.employees.id;


--
-- Name: exam_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_entries (
    id integer NOT NULL,
    exam_schedule_id integer NOT NULL,
    exam_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    subject_id integer NOT NULL,
    room character varying(50),
    supervisor_teacher_id integer,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.exam_entries OWNER TO postgres;

--
-- Name: exam_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exam_entries_id_seq OWNER TO postgres;

--
-- Name: exam_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_entries_id_seq OWNED BY public.exam_entries.id;


--
-- Name: exam_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_schedules (
    id integer NOT NULL,
    academic_year_id integer NOT NULL,
    stage_id integer NOT NULL,
    grade_id integer NOT NULL,
    section_id integer NOT NULL,
    term smallint DEFAULT 1 NOT NULL,
    status character varying(12) DEFAULT 'draft'::character varying NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT exam_schedules_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying])::text[]))),
    CONSTRAINT exam_schedules_term_check CHECK ((term = ANY (ARRAY[1, 2])))
);


ALTER TABLE public.exam_schedules OWNER TO postgres;

--
-- Name: exam_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_schedules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exam_schedules_id_seq OWNER TO postgres;

--
-- Name: exam_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_schedules_id_seq OWNED BY public.exam_schedules.id;


--
-- Name: exam_timetable_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_timetable_entries (
    id bigint NOT NULL,
    exam_timetable_id integer NOT NULL,
    exam_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    subject_id integer NOT NULL,
    room text,
    notes text,
    apply_to_section_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.exam_timetable_entries OWNER TO postgres;

--
-- Name: exam_timetable_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_timetable_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exam_timetable_entries_id_seq OWNER TO postgres;

--
-- Name: exam_timetable_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_timetable_entries_id_seq OWNED BY public.exam_timetable_entries.id;


--
-- Name: exam_timetables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_timetables (
    id integer NOT NULL,
    academic_year_id integer NOT NULL,
    stage_id integer NOT NULL,
    grade_id integer NOT NULL,
    scope character varying(10) NOT NULL,
    section_id integer,
    exam_type character varying(10) NOT NULL,
    month smallint,
    status character varying(10) DEFAULT 'draft'::character varying NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT exam_timetables_exam_type_check CHECK (((exam_type)::text = ANY ((ARRAY['monthly'::character varying, 'midyear'::character varying, 'final'::character varying])::text[]))),
    CONSTRAINT exam_timetables_month_check CHECK (((month >= 1) AND (month <= 12))),
    CONSTRAINT exam_timetables_scope_check CHECK (((scope)::text = ANY ((ARRAY['grade'::character varying, 'section'::character varying])::text[]))),
    CONSTRAINT exam_timetables_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying])::text[])))
);


ALTER TABLE public.exam_timetables OWNER TO postgres;

--
-- Name: exam_timetables_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_timetables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exam_timetables_id_seq OWNER TO postgres;

--
-- Name: exam_timetables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_timetables_id_seq OWNED BY public.exam_timetables.id;


--
-- Name: fee_contracts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fee_contracts (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    academic_year_id integer NOT NULL,
    annual_amount bigint NOT NULL,
    installments_count integer NOT NULL,
    first_due_date date NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    discount_amount numeric(10,2) DEFAULT 0,
    discount_reason character varying(255),
    CONSTRAINT fee_contracts_annual_amount_check CHECK ((annual_amount > 0)),
    CONSTRAINT fee_contracts_installments_count_check CHECK ((installments_count > 0)),
    CONSTRAINT fee_contracts_status_check CHECK ((status = ANY (ARRAY['active'::text, 'closed'::text, 'cancelled'::text])))
);


ALTER TABLE public.fee_contracts OWNER TO postgres;

--
-- Name: fee_contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fee_contracts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fee_contracts_id_seq OWNER TO postgres;

--
-- Name: fee_contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fee_contracts_id_seq OWNED BY public.fee_contracts.id;


--
-- Name: fee_installments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fee_installments (
    id bigint NOT NULL,
    contract_id bigint NOT NULL,
    installment_no integer NOT NULL,
    due_date date NOT NULL,
    amount bigint NOT NULL,
    paid_amount bigint DEFAULT 0 NOT NULL,
    status text DEFAULT 'unpaid'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fee_installments_amount_check CHECK ((amount > 0)),
    CONSTRAINT fee_installments_installment_no_check CHECK ((installment_no > 0)),
    CONSTRAINT fee_installments_paid_amount_check CHECK ((paid_amount >= 0)),
    CONSTRAINT fee_installments_status_check CHECK ((status = ANY (ARRAY['unpaid'::text, 'partial'::text, 'paid'::text, 'voided'::text])))
);


ALTER TABLE public.fee_installments OWNER TO postgres;

--
-- Name: fee_installments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fee_installments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fee_installments_id_seq OWNER TO postgres;

--
-- Name: fee_installments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fee_installments_id_seq OWNED BY public.fee_installments.id;


--
-- Name: fee_payment_allocations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fee_payment_allocations (
    id bigint NOT NULL,
    payment_id bigint NOT NULL,
    installment_id bigint NOT NULL,
    allocated_amount bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fee_payment_allocations_allocated_amount_check CHECK ((allocated_amount > 0))
);


ALTER TABLE public.fee_payment_allocations OWNER TO postgres;

--
-- Name: fee_payment_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fee_payment_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fee_payment_allocations_id_seq OWNER TO postgres;

--
-- Name: fee_payment_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fee_payment_allocations_id_seq OWNED BY public.fee_payment_allocations.id;


--
-- Name: fee_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fee_payments (
    id bigint NOT NULL,
    contract_id bigint NOT NULL,
    student_id text NOT NULL,
    amount bigint NOT NULL,
    method text NOT NULL,
    provider text,
    reference text,
    note text,
    attachment_path text,
    attachment_mime text,
    status text DEFAULT 'confirmed'::text NOT NULL,
    receipt_number text NOT NULL,
    paid_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fee_payments_amount_check CHECK ((amount > 0)),
    CONSTRAINT fee_payments_method_check CHECK ((method = ANY (ARRAY['cash'::text, 'transfer'::text, 'wallet'::text, 'card'::text, 'other'::text]))),
    CONSTRAINT fee_payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'failed'::text, 'voided'::text, 'refunded'::text])))
);


ALTER TABLE public.fee_payments OWNER TO postgres;

--
-- Name: fee_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fee_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fee_payments_id_seq OWNER TO postgres;

--
-- Name: fee_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fee_payments_id_seq OWNED BY public.fee_payments.id;


--
-- Name: fee_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fee_rules (
    id bigint NOT NULL,
    academic_year_id integer NOT NULL,
    scope text NOT NULL,
    stage_id integer,
    grade_id integer,
    section_id integer,
    student_id integer,
    annual_amount bigint NOT NULL,
    installments_count integer NOT NULL,
    first_due_date date NOT NULL,
    interval_months integer DEFAULT 1 NOT NULL,
    reason_code text,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fee_rules_scope_check CHECK ((scope = ANY (ARRAY['DEFAULT'::text, 'STAGE'::text, 'GRADE'::text, 'SECTION'::text, 'STUDENT'::text])))
);


ALTER TABLE public.fee_rules OWNER TO postgres;

--
-- Name: fee_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fee_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fee_rules_id_seq OWNER TO postgres;

--
-- Name: fee_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fee_rules_id_seq OWNED BY public.fee_rules.id;


--
-- Name: grade_change_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grade_change_logs (
    id bigint NOT NULL,
    grade_id bigint NOT NULL,
    changed_by bigint NOT NULL,
    old_status character varying(20),
    new_status character varying(20),
    old_score numeric(6,2),
    new_score numeric(6,2),
    reason character varying(255),
    changed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.grade_change_logs OWNER TO postgres;

--
-- Name: grade_change_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grade_change_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.grade_change_logs_id_seq OWNER TO postgres;

--
-- Name: grade_change_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grade_change_logs_id_seq OWNED BY public.grade_change_logs.id;


--
-- Name: grade_policies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grade_policies (
    id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    term smallint NOT NULL,
    subject_id bigint NOT NULL,
    stage_id bigint,
    grade_id bigint,
    weights_json jsonb NOT NULL,
    rounding_rule character varying(30),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    midterm_aggregate_weight numeric(5,2),
    midterm_exam_weight numeric(5,2),
    final_aggregate_weight numeric(5,2),
    final_exam_weight numeric(5,2),
    max_total_score numeric(5,2),
    passing_score numeric(5,2),
    monthly_exam_count smallint,
    is_active boolean DEFAULT true NOT NULL,
    notes text
);


ALTER TABLE public.grade_policies OWNER TO postgres;

--
-- Name: COLUMN grade_policies.midterm_aggregate_weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.grade_policies.midterm_aggregate_weight IS 'وزن أعمال ما قبل النصفي';


--
-- Name: COLUMN grade_policies.midterm_exam_weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.grade_policies.midterm_exam_weight IS 'وزن اختبار النصفي';


--
-- Name: COLUMN grade_policies.final_aggregate_weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.grade_policies.final_aggregate_weight IS 'وزن أعمال ما بعد النصفي';


--
-- Name: COLUMN grade_policies.final_exam_weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.grade_policies.final_exam_weight IS 'وزن اختبار النهائي';


--
-- Name: COLUMN grade_policies.max_total_score; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.grade_policies.max_total_score IS 'المجموع النهائي المعتمد عادة 100';


--
-- Name: COLUMN grade_policies.passing_score; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.grade_policies.passing_score IS 'درجة النجاح';


--
-- Name: COLUMN grade_policies.monthly_exam_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.grade_policies.monthly_exam_count IS 'عدد الاختبارات الشهرية المعتمدة ضمن السياسة';


--
-- Name: grade_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grade_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.grade_policies_id_seq OWNER TO postgres;

--
-- Name: grade_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grade_policies_id_seq OWNED BY public.grade_policies.id;


--
-- Name: grade_subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grade_subjects (
    id integer NOT NULL,
    grade_id integer NOT NULL,
    subject_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.grade_subjects OWNER TO postgres;

--
-- Name: grade_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.grade_subjects ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.grade_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: grades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grades (
    id integer NOT NULL,
    stage_id integer NOT NULL,
    name character varying(120) NOT NULL,
    grade_name character varying(120) GENERATED ALWAYS AS (name) STORED,
    order_no smallint DEFAULT 1 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    order_index integer DEFAULT 0 NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.grades OWNER TO postgres;

--
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.grades ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: guardians; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.guardians (
    id integer NOT NULL,
    user_id integer,
    full_name character varying(150) NOT NULL,
    gender character varying(10),
    phone character varying(20) NOT NULL,
    email character varying(150),
    address text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    school_id bigint NOT NULL
);


ALTER TABLE public.guardians OWNER TO postgres;

--
-- Name: guardians_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.guardians_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.guardians_id_seq OWNER TO postgres;

--
-- Name: guardians_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.guardians_id_seq OWNED BY public.guardians.id;


--
-- Name: lesson_substitutions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lesson_substitutions (
    id integer NOT NULL,
    substitution_date date NOT NULL,
    timetable_entry_id integer,
    absent_teacher_id integer,
    substitute_teacher_id integer,
    assigned_by_user_id integer,
    created_at timestamp with time zone DEFAULT now(),
    status character varying(20) DEFAULT 'pending_teacher'::character varying
);


ALTER TABLE public.lesson_substitutions OWNER TO postgres;

--
-- Name: lesson_substitutions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lesson_substitutions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lesson_substitutions_id_seq OWNER TO postgres;

--
-- Name: lesson_substitutions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lesson_substitutions_id_seq OWNED BY public.lesson_substitutions.id;


--
-- Name: modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modules (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.modules OWNER TO postgres;

--
-- Name: modules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.modules_id_seq OWNER TO postgres;

--
-- Name: modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modules_id_seq OWNED BY public.modules.id;


--
-- Name: notification_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_attachments (
    id bigint NOT NULL,
    notification_id bigint NOT NULL,
    kind character varying(20) NOT NULL,
    original_name text,
    mime_type text,
    size_bytes bigint,
    storage_path text,
    link_url text,
    link_label text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notification_attachments OWNER TO postgres;

--
-- Name: notification_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_attachments_id_seq OWNER TO postgres;

--
-- Name: notification_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_attachments_id_seq OWNED BY public.notification_attachments.id;


--
-- Name: notification_recipients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_recipients (
    id bigint NOT NULL,
    notification_id bigint NOT NULL,
    recipient_user_id integer NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notification_recipients OWNER TO postgres;

--
-- Name: notification_recipients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_recipients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_recipients_id_seq OWNER TO postgres;

--
-- Name: notification_recipients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_recipients_id_seq OWNED BY public.notification_recipients.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    source character varying(20) NOT NULL,
    category character varying(50) DEFAULT 'general'::character varying NOT NULL,
    priority character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    sender_user_id integer,
    sender_display_name text,
    related_type character varying(100),
    related_id bigint,
    meta jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notifications_priority_check CHECK (((priority)::text = ANY ((ARRAY['normal'::character varying, 'important'::character varying, 'urgent'::character varying])::text[]))),
    CONSTRAINT notifications_source_check CHECK (((source)::text = ANY ((ARRAY['manual'::character varying, 'system'::character varying])::text[])))
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: periods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.periods (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    sort_order integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.periods OWNER TO postgres;

--
-- Name: periods_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.periods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.periods_id_seq OWNER TO postgres;

--
-- Name: periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.periods_id_seq OWNED BY public.periods.id;


--
-- Name: permission_request_recipients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permission_request_recipients (
    id bigint NOT NULL,
    request_id bigint NOT NULL,
    teacher_id integer NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.permission_request_recipients OWNER TO postgres;

--
-- Name: permission_request_recipients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permission_request_recipients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permission_request_recipients_id_seq OWNER TO postgres;

--
-- Name: permission_request_recipients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permission_request_recipients_id_seq OWNED BY public.permission_request_recipients.id;


--
-- Name: permission_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permission_requests (
    id bigint NOT NULL,
    student_id integer NOT NULL,
    parent_user_id integer NOT NULL,
    request_date date NOT NULL,
    type character varying(20) NOT NULL,
    time_from time without time zone,
    time_to time without time zone,
    reason_text text,
    attachment_url text,
    status character varying(12) DEFAULT 'PENDING'::character varying NOT NULL,
    decided_by_user_id integer,
    decided_at timestamp with time zone,
    decision_note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT chk_permission_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying])::text[]))),
    CONSTRAINT chk_permission_times CHECK (((((type)::text = 'ABSENCE'::text) AND (time_from IS NULL) AND (time_to IS NULL)) OR (((type)::text = 'LATE'::text) AND (time_from IS NOT NULL)) OR (((type)::text = 'EARLY_LEAVE'::text) AND (time_to IS NOT NULL)))),
    CONSTRAINT chk_permission_type CHECK (((type)::text = ANY ((ARRAY['ABSENCE'::character varying, 'LATE'::character varying, 'EARLY_LEAVE'::character varying])::text[])))
);


ALTER TABLE public.permission_requests OWNER TO postgres;

--
-- Name: permission_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permission_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permission_requests_id_seq OWNER TO postgres;

--
-- Name: permission_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permission_requests_id_seq OWNED BY public.permission_requests.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id integer NOT NULL,
    module_id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permissions_id_seq OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permissions (
    id integer NOT NULL,
    role_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.role_permissions OWNER TO postgres;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_permissions_id_seq OWNER TO postgres;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.role_permissions_id_seq OWNED BY public.role_permissions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: scan_token_uses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scan_token_uses (
    jti text NOT NULL,
    used_at timestamp with time zone DEFAULT now() NOT NULL,
    teacher_id integer NOT NULL,
    session_id bigint NOT NULL,
    student_id integer NOT NULL
);


ALTER TABLE public.scan_token_uses OWNER TO postgres;

--
-- Name: school_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.school_settings (
    id bigint NOT NULL,
    school_id bigint NOT NULL,
    default_language character varying(20) DEFAULT 'ar'::character varying NOT NULL,
    grading_scale character varying(50) DEFAULT '100'::character varying NOT NULL,
    pass_mark numeric(5,2) DEFAULT 50.00 NOT NULL,
    attendance_policy character varying(50) DEFAULT 'daily'::character varying NOT NULL,
    invoice_prefix character varying(20),
    student_code_prefix character varying(20),
    academic_year_starts_on date,
    week_start_day smallint DEFAULT 6 NOT NULL,
    max_students integer,
    max_teachers integer,
    allow_parent_portal boolean DEFAULT true NOT NULL,
    allow_teacher_portal boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_school_settings_pass_mark CHECK (((pass_mark >= (0)::numeric) AND (pass_mark <= (100)::numeric))),
    CONSTRAINT ck_school_settings_week_start_day CHECK (((week_start_day >= 0) AND (week_start_day <= 6)))
);


ALTER TABLE public.school_settings OWNER TO postgres;

--
-- Name: school_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.school_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.school_settings_id_seq OWNER TO postgres;

--
-- Name: school_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.school_settings_id_seq OWNED BY public.school_settings.id;


--
-- Name: schools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schools (
    id bigint NOT NULL,
    name_ar character varying(255) NOT NULL,
    name_en character varying(255),
    slug character varying(150) NOT NULL,
    code character varying(50) NOT NULL,
    logo_url text,
    phone character varying(50),
    alt_phone character varying(50),
    email character varying(255),
    website character varying(255),
    country character varying(100),
    city character varying(100),
    address text,
    timezone character varying(100) DEFAULT 'Asia/Aden'::character varying NOT NULL,
    currency_code character varying(10) DEFAULT 'YER'::character varying NOT NULL,
    principal_name character varying(255),
    established_date date,
    license_number character varying(100),
    subscription_status character varying(30) DEFAULT 'trial'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_schools_slug_format CHECK (((slug)::text ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'::text)),
    CONSTRAINT ck_schools_subscription_status CHECK (((subscription_status)::text = ANY ((ARRAY['trial'::character varying, 'active'::character varying, 'suspended'::character varying, 'expired'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.schools OWNER TO postgres;

--
-- Name: schools_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schools_id_seq OWNER TO postgres;

--
-- Name: schools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schools_id_seq OWNED BY public.schools.id;


--
-- Name: schools_master_registry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schools_master_registry (
    id integer NOT NULL,
    admin_email character varying(255) NOT NULL,
    db_name character varying(100) NOT NULL,
    school_name_ar character varying(255),
    school_name_en character varying(255),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.schools_master_registry OWNER TO postgres;

--
-- Name: schools_master_registry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schools_master_registry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schools_master_registry_id_seq OWNER TO postgres;

--
-- Name: schools_master_registry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schools_master_registry_id_seq OWNED BY public.schools_master_registry.id;


--
-- Name: section_advisors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.section_advisors (
    id integer NOT NULL,
    academic_year_id integer NOT NULL,
    term smallint NOT NULL,
    section_id integer NOT NULL,
    teacher_id integer NOT NULL,
    role character varying(20) DEFAULT 'homeroom'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT section_advisors_role_check CHECK (((role)::text = ANY ((ARRAY['homeroom'::character varying, 'counselor'::character varying])::text[]))),
    CONSTRAINT section_advisors_term_check CHECK ((term = ANY (ARRAY[1, 2])))
);


ALTER TABLE public.section_advisors OWNER TO postgres;

--
-- Name: section_advisors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.section_advisors ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.section_advisors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: section_subject_teachers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.section_subject_teachers (
    id integer NOT NULL,
    academic_year_id integer NOT NULL,
    term smallint NOT NULL,
    section_id integer NOT NULL,
    subject_id integer NOT NULL,
    teacher_id integer NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL,
    CONSTRAINT section_subject_teachers_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying])::text[]))),
    CONSTRAINT section_subject_teachers_term_check CHECK ((term = ANY (ARRAY[1, 2])))
);


ALTER TABLE public.section_subject_teachers OWNER TO postgres;

--
-- Name: section_subject_teachers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.section_subject_teachers ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.section_subject_teachers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sections (
    id integer NOT NULL,
    grade_id integer NOT NULL,
    name character varying(20) NOT NULL,
    capacity smallint,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    school_id bigint NOT NULL
);


ALTER TABLE public.sections OWNER TO postgres;

--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sections_id_seq OWNER TO postgres;

--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sections_id_seq OWNED BY public.sections.id;


--
-- Name: stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stages (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    order_no smallint DEFAULT 1 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    order_index integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.stages OWNER TO postgres;

--
-- Name: stages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.stages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.stages_id_seq OWNER TO postgres;

--
-- Name: stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.stages_id_seq OWNED BY public.stages.id;


--
-- Name: student_enrollments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_enrollments (
    id integer NOT NULL,
    student_id integer NOT NULL,
    academic_year_id integer NOT NULL,
    stage_id integer NOT NULL,
    grade_id integer NOT NULL,
    section_id integer,
    roll_number integer,
    status character varying(20) DEFAULT 'enrolled'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    term integer DEFAULT 1 NOT NULL,
    school_id bigint NOT NULL,
    CONSTRAINT student_enrollments_term_chk CHECK ((term = ANY (ARRAY[1, 2])))
);


ALTER TABLE public.student_enrollments OWNER TO postgres;

--
-- Name: student_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_enrollments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.student_enrollments_id_seq OWNER TO postgres;

--
-- Name: student_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_enrollments_id_seq OWNED BY public.student_enrollments.id;


--
-- Name: student_guardians; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_guardians (
    id integer NOT NULL,
    student_id integer NOT NULL,
    guardian_id integer NOT NULL,
    relation character varying(50),
    is_primary boolean DEFAULT true NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.student_guardians OWNER TO postgres;

--
-- Name: student_guardians_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_guardians_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.student_guardians_id_seq OWNER TO postgres;

--
-- Name: student_guardians_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_guardians_id_seq OWNED BY public.student_guardians.id;


--
-- Name: student_year_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_year_results (
    id integer NOT NULL,
    student_id integer NOT NULL,
    academic_year_id integer NOT NULL,
    result character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    reason text,
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    decided_at timestamp with time zone,
    decided_by integer,
    CONSTRAINT student_year_results_result_check CHECK (((result)::text = ANY ((ARRAY['pending'::character varying, 'passed'::character varying, 'failed'::character varying, 'excluded'::character varying])::text[]))),
    CONSTRAINT student_year_results_result_chk CHECK (((result)::text = ANY ((ARRAY['pending'::character varying, 'passed'::character varying, 'failed'::character varying, 'transferred'::character varying, 'withdrawn'::character varying, 'graduated'::character varying])::text[])))
);


ALTER TABLE public.student_year_results OWNER TO postgres;

--
-- Name: student_year_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_year_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.student_year_results_id_seq OWNER TO postgres;

--
-- Name: student_year_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_year_results_id_seq OWNED BY public.student_year_results.id;


--
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    id integer NOT NULL,
    user_id integer,
    student_code character varying(50) NOT NULL,
    full_name character varying(150) NOT NULL,
    gender character varying(10) NOT NULL,
    birth_date date NOT NULL,
    birth_place character varying(150),
    address text,
    phone character varying(20),
    phone2 character varying(20),
    admission_date date NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    school_id bigint NOT NULL
);


ALTER TABLE public.students OWNER TO postgres;

--
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.students_id_seq OWNER TO postgres;

--
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.students_id_seq OWNED BY public.students.id;


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subjects (
    id integer NOT NULL,
    name character varying(120) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.subjects OWNER TO postgres;

--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subjects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subjects_id_seq OWNER TO postgres;

--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subjects_id_seq OWNED BY public.subjects.id;


--
-- Name: submission_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submission_attachments (
    id bigint NOT NULL,
    submission_id bigint NOT NULL,
    file_url text NOT NULL,
    file_name character varying(255),
    file_type character varying(80),
    file_size bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.submission_attachments OWNER TO postgres;

--
-- Name: submission_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.submission_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submission_attachments_id_seq OWNER TO postgres;

--
-- Name: submission_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.submission_attachments_id_seq OWNED BY public.submission_attachments.id;


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submissions (
    id bigint NOT NULL,
    assessment_id bigint NOT NULL,
    student_id integer NOT NULL,
    status character varying(20) DEFAULT 'submitted'::character varying NOT NULL,
    note text,
    submitted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.submissions OWNER TO postgres;

--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submissions_id_seq OWNER TO postgres;

--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.submissions_id_seq OWNED BY public.submissions.id;


--
-- Name: teacher_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_assignments (
    id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    academic_year_id bigint NOT NULL,
    term smallint NOT NULL,
    stage_id bigint,
    grade_id bigint,
    section_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.teacher_assignments OWNER TO postgres;

--
-- Name: teacher_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_assignments_id_seq OWNER TO postgres;

--
-- Name: teacher_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_assignments_id_seq OWNED BY public.teacher_assignments.id;


--
-- Name: teacher_attendance_corrections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_attendance_corrections (
    id bigint NOT NULL,
    entry_id bigint NOT NULL,
    day_id bigint NOT NULL,
    teacher_id integer NOT NULL,
    old_status text NOT NULL,
    new_status text NOT NULL,
    reason text,
    corrected_by_user_id integer NOT NULL,
    corrected_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_teacher_att_corr_status CHECK (((old_status = ANY (ARRAY['present'::text, 'absent'::text])) AND (new_status = ANY (ARRAY['present'::text, 'absent'::text]))))
);


ALTER TABLE public.teacher_attendance_corrections OWNER TO postgres;

--
-- Name: teacher_attendance_corrections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_attendance_corrections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_attendance_corrections_id_seq OWNER TO postgres;

--
-- Name: teacher_attendance_corrections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_attendance_corrections_id_seq OWNED BY public.teacher_attendance_corrections.id;


--
-- Name: teacher_attendance_days; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_attendance_days (
    id bigint NOT NULL,
    attendance_date date NOT NULL,
    academic_year_id integer,
    is_locked boolean DEFAULT false NOT NULL,
    locked_by_user_id integer,
    locked_at timestamp with time zone,
    created_by_user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT chk_teacher_att_days_lock_fields CHECK ((((is_locked = false) AND (locked_at IS NULL)) OR ((is_locked = true) AND (locked_at IS NOT NULL))))
);


ALTER TABLE public.teacher_attendance_days OWNER TO postgres;

--
-- Name: teacher_attendance_days_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_attendance_days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_attendance_days_id_seq OWNER TO postgres;

--
-- Name: teacher_attendance_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_attendance_days_id_seq OWNED BY public.teacher_attendance_days.id;


--
-- Name: teacher_attendance_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_attendance_entries (
    id bigint NOT NULL,
    day_id bigint NOT NULL,
    teacher_id integer NOT NULL,
    status text DEFAULT 'present'::text NOT NULL,
    method text DEFAULT 'scan'::text NOT NULL,
    scanned_card_uid text,
    notes text,
    recorded_by_user_id integer,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    scanned_card_id bigint,
    CONSTRAINT chk_teacher_att_entries_method CHECK ((method = ANY (ARRAY['scan'::text, 'manual'::text, 'system'::text]))),
    CONSTRAINT chk_teacher_att_entries_status CHECK ((status = ANY (ARRAY['present'::text, 'absent'::text])))
);


ALTER TABLE public.teacher_attendance_entries OWNER TO postgres;

--
-- Name: teacher_attendance_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_attendance_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_attendance_entries_id_seq OWNER TO postgres;

--
-- Name: teacher_attendance_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_attendance_entries_id_seq OWNED BY public.teacher_attendance_entries.id;


--
-- Name: teacher_attendance_scan_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_attendance_scan_events (
    id bigint NOT NULL,
    day_id bigint NOT NULL,
    teacher_id integer,
    raw_code text NOT NULL,
    normalized_code text NOT NULL,
    source text DEFAULT 'scanner'::text NOT NULL,
    ip_address text,
    user_agent text,
    created_by_user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    card_id bigint,
    CONSTRAINT chk_teacher_att_scan_source CHECK ((source = ANY (ARRAY['scanner'::text, 'camera'::text, 'manual'::text])))
);


ALTER TABLE public.teacher_attendance_scan_events OWNER TO postgres;

--
-- Name: teacher_attendance_scan_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_attendance_scan_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_attendance_scan_events_id_seq OWNER TO postgres;

--
-- Name: teacher_attendance_scan_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_attendance_scan_events_id_seq OWNED BY public.teacher_attendance_scan_events.id;


--
-- Name: teacher_attendance_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_attendance_settings (
    id bigint NOT NULL,
    duty_start_time time without time zone DEFAULT '07:00:00'::time without time zone NOT NULL,
    grace_minutes integer DEFAULT 0 NOT NULL,
    allow_mark_absent boolean DEFAULT true NOT NULL,
    lock_after_minutes integer,
    created_by_user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT chk_teacher_att_settings_grace CHECK ((grace_minutes >= 0)),
    CONSTRAINT chk_teacher_att_settings_lock_after CHECK (((lock_after_minutes IS NULL) OR (lock_after_minutes >= 0)))
);


ALTER TABLE public.teacher_attendance_settings OWNER TO postgres;

--
-- Name: teacher_attendance_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_attendance_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_attendance_settings_id_seq OWNER TO postgres;

--
-- Name: teacher_attendance_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_attendance_settings_id_seq OWNED BY public.teacher_attendance_settings.id;


--
-- Name: teacher_barcode_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_barcode_tokens (
    teacher_id integer NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.teacher_barcode_tokens OWNER TO postgres;

--
-- Name: teacher_cards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_cards (
    id bigint NOT NULL,
    teacher_id integer NOT NULL,
    card_uid text NOT NULL,
    card_type text DEFAULT 'qr'::text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT chk_teacher_cards_card_type CHECK ((card_type = ANY (ARRAY['qr'::text, 'barcode'::text, 'nfc'::text, 'other'::text])))
);


ALTER TABLE public.teacher_cards OWNER TO postgres;

--
-- Name: teacher_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_cards_id_seq OWNER TO postgres;

--
-- Name: teacher_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_cards_id_seq OWNED BY public.teacher_cards.id;


--
-- Name: teacher_lesson_presence; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_lesson_presence (
    id bigint NOT NULL,
    presence_date date NOT NULL,
    teacher_id integer NOT NULL,
    timetable_entry_id bigint NOT NULL,
    attendance_session_id bigint,
    status text DEFAULT 'taught'::text NOT NULL,
    permission_request_id bigint,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT chk_tlp_excused_has_permission CHECK (((status <> 'excused'::text) OR (permission_request_id IS NOT NULL))),
    CONSTRAINT chk_tlp_status CHECK ((status = ANY (ARRAY['taught'::text, 'missed'::text, 'excused'::text, 'cancelled'::text])))
);


ALTER TABLE public.teacher_lesson_presence OWNER TO postgres;

--
-- Name: teacher_lesson_presence_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_lesson_presence_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_lesson_presence_id_seq OWNER TO postgres;

--
-- Name: teacher_lesson_presence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_lesson_presence_id_seq OWNED BY public.teacher_lesson_presence.id;


--
-- Name: teacher_permission_request_slots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_permission_request_slots (
    id bigint NOT NULL,
    permission_request_id bigint NOT NULL,
    timetable_entry_id bigint NOT NULL
);


ALTER TABLE public.teacher_permission_request_slots OWNER TO postgres;

--
-- Name: teacher_permission_request_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_permission_request_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_permission_request_slots_id_seq OWNER TO postgres;

--
-- Name: teacher_permission_request_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_permission_request_slots_id_seq OWNED BY public.teacher_permission_request_slots.id;


--
-- Name: teacher_permission_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_permission_requests (
    id bigint NOT NULL,
    teacher_id integer NOT NULL,
    request_date date NOT NULL,
    scope text DEFAULT 'full_day'::text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    reason_text text,
    notes text,
    requested_at timestamp with time zone DEFAULT now() NOT NULL,
    decided_at timestamp with time zone,
    decided_by_user_id integer,
    decision_note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT chk_teacher_perm_decision_fields CHECK (((status = 'pending'::text) OR ((status = ANY (ARRAY['approved'::text, 'rejected'::text])) AND (decided_at IS NOT NULL)))),
    CONSTRAINT chk_teacher_perm_scope CHECK ((scope = ANY (ARRAY['full_day'::text, 'slots'::text]))),
    CONSTRAINT chk_teacher_perm_status CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])))
);


ALTER TABLE public.teacher_permission_requests OWNER TO postgres;

--
-- Name: teacher_permission_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teacher_permission_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_permission_requests_id_seq OWNER TO postgres;

--
-- Name: teacher_permission_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teacher_permission_requests_id_seq OWNED BY public.teacher_permission_requests.id;


--
-- Name: teacher_subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teacher_subjects (
    id integer NOT NULL,
    teacher_id integer NOT NULL,
    subject_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.teacher_subjects OWNER TO postgres;

--
-- Name: teacher_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.teacher_subjects ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.teacher_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: teachers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teachers (
    id integer NOT NULL,
    user_id integer,
    full_name character varying(150) NOT NULL,
    phone character varying(30),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL
);


ALTER TABLE public.teachers OWNER TO postgres;

--
-- Name: teachers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teachers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teachers_id_seq OWNER TO postgres;

--
-- Name: teachers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teachers_id_seq OWNED BY public.teachers.id;


--
-- Name: timetable_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.timetable_entries (
    id integer NOT NULL,
    timetable_id integer NOT NULL,
    day_of_week smallint NOT NULL,
    period_id integer NOT NULL,
    subject_id integer NOT NULL,
    teacher_id integer NOT NULL,
    room character varying(50),
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL,
    CONSTRAINT timetable_entries_day_of_week_check CHECK (((day_of_week >= 1) AND (day_of_week <= 7)))
);


ALTER TABLE public.timetable_entries OWNER TO postgres;

--
-- Name: timetable_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.timetable_entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timetable_entries_id_seq OWNER TO postgres;

--
-- Name: timetable_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.timetable_entries_id_seq OWNED BY public.timetable_entries.id;


--
-- Name: timetable_overrides; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.timetable_overrides (
    id bigint NOT NULL,
    timetable_id integer NOT NULL,
    date date NOT NULL,
    day_of_week smallint NOT NULL,
    period_id integer NOT NULL,
    type text NOT NULL,
    subject_id integer,
    teacher_id integer,
    room text,
    notes text,
    exam_title text,
    exam_kind text,
    exam_total integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    school_id bigint NOT NULL,
    CONSTRAINT timetable_overrides_day_of_week_check CHECK (((day_of_week >= 1) AND (day_of_week <= 7))),
    CONSTRAINT timetable_overrides_type_check CHECK ((type = ANY (ARRAY['lesson'::text, 'exam'::text, 'cancel'::text])))
);


ALTER TABLE public.timetable_overrides OWNER TO postgres;

--
-- Name: timetable_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.timetable_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timetable_overrides_id_seq OWNER TO postgres;

--
-- Name: timetable_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.timetable_overrides_id_seq OWNED BY public.timetable_overrides.id;


--
-- Name: timetables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.timetables (
    id integer NOT NULL,
    academic_year_id integer NOT NULL,
    stage_id integer NOT NULL,
    grade_id integer NOT NULL,
    section_id integer NOT NULL,
    term smallint DEFAULT 1 NOT NULL,
    status character varying(12) DEFAULT 'draft'::character varying NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id bigint NOT NULL,
    CONSTRAINT timetables_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying])::text[]))),
    CONSTRAINT timetables_term_check CHECK ((term = ANY (ARRAY[1, 2])))
);


ALTER TABLE public.timetables OWNER TO postgres;

--
-- Name: timetables_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.timetables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timetables_id_seq OWNER TO postgres;

--
-- Name: timetables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.timetables_id_seq OWNED BY public.timetables.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_roles_id_seq OWNER TO postgres;

--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    username character varying(100) NOT NULL,
    phone character varying(20),
    password_hash text NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    token_version integer DEFAULT 1,
    school_id bigint NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: academic_years id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_years ALTER COLUMN id SET DEFAULT nextval('public.academic_years_id_seq'::regclass);


--
-- Name: assessment_attachments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_attachments ALTER COLUMN id SET DEFAULT nextval('public.assessment_attachments_id_seq'::regclass);


--
-- Name: assessment_grades id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_grades ALTER COLUMN id SET DEFAULT nextval('public.assessment_grades_id_seq'::regclass);


--
-- Name: assessment_reopen_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_reopen_requests ALTER COLUMN id SET DEFAULT nextval('public.assessment_reopen_requests_id_seq'::regclass);


--
-- Name: assessments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessments ALTER COLUMN id SET DEFAULT nextval('public.assessments_id_seq'::regclass);


--
-- Name: attendance_entries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entries ALTER COLUMN id SET DEFAULT nextval('public.attendance_entries_id_seq'::regclass);


--
-- Name: attendance_entry_corrections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entry_corrections ALTER COLUMN id SET DEFAULT nextval('public.attendance_entry_corrections_id_seq'::regclass);


--
-- Name: attendance_reasons id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_reasons ALTER COLUMN id SET DEFAULT nextval('public.attendance_reasons_id_seq'::regclass);


--
-- Name: attendance_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions ALTER COLUMN id SET DEFAULT nextval('public.attendance_sessions_id_seq'::regclass);


--
-- Name: continuing_batch_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items ALTER COLUMN id SET DEFAULT nextval('public.continuing_batch_items_id_seq'::regclass);


--
-- Name: continuing_batches id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batches ALTER COLUMN id SET DEFAULT nextval('public.continuing_batches_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_id_seq'::regclass);


--
-- Name: exam_entries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_entries ALTER COLUMN id SET DEFAULT nextval('public.exam_entries_id_seq'::regclass);


--
-- Name: exam_schedules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules ALTER COLUMN id SET DEFAULT nextval('public.exam_schedules_id_seq'::regclass);


--
-- Name: exam_timetable_entries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetable_entries ALTER COLUMN id SET DEFAULT nextval('public.exam_timetable_entries_id_seq'::regclass);


--
-- Name: exam_timetables id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetables ALTER COLUMN id SET DEFAULT nextval('public.exam_timetables_id_seq'::regclass);


--
-- Name: fee_contracts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_contracts ALTER COLUMN id SET DEFAULT nextval('public.fee_contracts_id_seq'::regclass);


--
-- Name: fee_installments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_installments ALTER COLUMN id SET DEFAULT nextval('public.fee_installments_id_seq'::regclass);


--
-- Name: fee_payment_allocations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payment_allocations ALTER COLUMN id SET DEFAULT nextval('public.fee_payment_allocations_id_seq'::regclass);


--
-- Name: fee_payments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payments ALTER COLUMN id SET DEFAULT nextval('public.fee_payments_id_seq'::regclass);


--
-- Name: fee_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_rules ALTER COLUMN id SET DEFAULT nextval('public.fee_rules_id_seq'::regclass);


--
-- Name: grade_change_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_change_logs ALTER COLUMN id SET DEFAULT nextval('public.grade_change_logs_id_seq'::regclass);


--
-- Name: grade_policies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_policies ALTER COLUMN id SET DEFAULT nextval('public.grade_policies_id_seq'::regclass);


--
-- Name: guardians id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guardians ALTER COLUMN id SET DEFAULT nextval('public.guardians_id_seq'::regclass);


--
-- Name: lesson_substitutions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson_substitutions ALTER COLUMN id SET DEFAULT nextval('public.lesson_substitutions_id_seq'::regclass);


--
-- Name: modules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules ALTER COLUMN id SET DEFAULT nextval('public.modules_id_seq'::regclass);


--
-- Name: notification_attachments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_attachments ALTER COLUMN id SET DEFAULT nextval('public.notification_attachments_id_seq'::regclass);


--
-- Name: notification_recipients id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_recipients ALTER COLUMN id SET DEFAULT nextval('public.notification_recipients_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: periods id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.periods ALTER COLUMN id SET DEFAULT nextval('public.periods_id_seq'::regclass);


--
-- Name: permission_request_recipients id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_request_recipients ALTER COLUMN id SET DEFAULT nextval('public.permission_request_recipients_id_seq'::regclass);


--
-- Name: permission_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_requests ALTER COLUMN id SET DEFAULT nextval('public.permission_requests_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: role_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN id SET DEFAULT nextval('public.role_permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: school_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.school_settings ALTER COLUMN id SET DEFAULT nextval('public.school_settings_id_seq'::regclass);


--
-- Name: schools id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools ALTER COLUMN id SET DEFAULT nextval('public.schools_id_seq'::regclass);


--
-- Name: schools_master_registry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools_master_registry ALTER COLUMN id SET DEFAULT nextval('public.schools_master_registry_id_seq'::regclass);


--
-- Name: sections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sections ALTER COLUMN id SET DEFAULT nextval('public.sections_id_seq'::regclass);


--
-- Name: stages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stages ALTER COLUMN id SET DEFAULT nextval('public.stages_id_seq'::regclass);


--
-- Name: student_enrollments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments ALTER COLUMN id SET DEFAULT nextval('public.student_enrollments_id_seq'::regclass);


--
-- Name: student_guardians id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_guardians ALTER COLUMN id SET DEFAULT nextval('public.student_guardians_id_seq'::regclass);


--
-- Name: student_year_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_year_results ALTER COLUMN id SET DEFAULT nextval('public.student_year_results_id_seq'::regclass);


--
-- Name: students id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students ALTER COLUMN id SET DEFAULT nextval('public.students_id_seq'::regclass);


--
-- Name: subjects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects ALTER COLUMN id SET DEFAULT nextval('public.subjects_id_seq'::regclass);


--
-- Name: submission_attachments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_attachments ALTER COLUMN id SET DEFAULT nextval('public.submission_attachments_id_seq'::regclass);


--
-- Name: submissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions ALTER COLUMN id SET DEFAULT nextval('public.submissions_id_seq'::regclass);


--
-- Name: teacher_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_assignments ALTER COLUMN id SET DEFAULT nextval('public.teacher_assignments_id_seq'::regclass);


--
-- Name: teacher_attendance_corrections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_corrections ALTER COLUMN id SET DEFAULT nextval('public.teacher_attendance_corrections_id_seq'::regclass);


--
-- Name: teacher_attendance_days id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_days ALTER COLUMN id SET DEFAULT nextval('public.teacher_attendance_days_id_seq'::regclass);


--
-- Name: teacher_attendance_entries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_entries ALTER COLUMN id SET DEFAULT nextval('public.teacher_attendance_entries_id_seq'::regclass);


--
-- Name: teacher_attendance_scan_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_scan_events ALTER COLUMN id SET DEFAULT nextval('public.teacher_attendance_scan_events_id_seq'::regclass);


--
-- Name: teacher_attendance_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_settings ALTER COLUMN id SET DEFAULT nextval('public.teacher_attendance_settings_id_seq'::regclass);


--
-- Name: teacher_cards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_cards ALTER COLUMN id SET DEFAULT nextval('public.teacher_cards_id_seq'::regclass);


--
-- Name: teacher_lesson_presence id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_lesson_presence ALTER COLUMN id SET DEFAULT nextval('public.teacher_lesson_presence_id_seq'::regclass);


--
-- Name: teacher_permission_request_slots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_request_slots ALTER COLUMN id SET DEFAULT nextval('public.teacher_permission_request_slots_id_seq'::regclass);


--
-- Name: teacher_permission_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_requests ALTER COLUMN id SET DEFAULT nextval('public.teacher_permission_requests_id_seq'::regclass);


--
-- Name: teachers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers ALTER COLUMN id SET DEFAULT nextval('public.teachers_id_seq'::regclass);


--
-- Name: timetable_entries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries ALTER COLUMN id SET DEFAULT nextval('public.timetable_entries_id_seq'::regclass);


--
-- Name: timetable_overrides id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides ALTER COLUMN id SET DEFAULT nextval('public.timetable_overrides_id_seq'::regclass);


--
-- Name: timetables id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables ALTER COLUMN id SET DEFAULT nextval('public.timetables_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: academic_years; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.academic_years (id, name, start_date, end_date, is_active, created_at, updated_at, school_id) FROM stdin;
2	2025-2026	2025-09-01	2026-06-30	t	2025-12-12 04:14:45.477248+03	\N	3
4	2030/2031	2026-01-02	2026-12-14	f	2026-01-14 01:01:11.623878+03	2026-01-17 22:34:21.326098+03	3
3	2027/2026	2026-01-20	2026-12-13	f	2026-01-13 22:25:04.591165+03	2026-01-17 22:34:24.346174+03	3
1	2024-2025	2024-09-01	2025-06-30	f	2025-12-12 04:14:45.477248+03	2026-01-17 22:34:30.399914+03	3
2026	السنة الأكاديمية 2026	2026-01-01	2026-12-31	f	2026-01-18 22:31:37.452223+03	\N	3
\.


--
-- Data for Name: assessment_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assessment_attachments (id, assessment_id, file_url, file_name, file_type, file_size, created_at) FROM stdin;
1	8	/uploads/assessments/asm_1774447856902_571027005.png	ââÙÙØ·Ø© Ø§ÙØ´Ø§Ø´Ø© (99).png	image/png	465560	2026-03-25 17:10:57.032238+03
2	9	/uploads/assessments/asm_1774448466381_169991515.png	ââÙÙØ·Ø© Ø§ÙØ´Ø§Ø´Ø© (119).png	image/png	231862	2026-03-25 17:21:06.567809+03
3	11	/uploads/assessments/asm_1774450580686_830424578.png	ââÙÙØ·Ø© Ø§ÙØ´Ø§Ø´Ø© (99).png	image/png	465560	2026-03-25 17:56:20.828431+03
\.


--
-- Data for Name: assessment_grades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assessment_grades (id, assessment_id, student_id, status, score, feedback, graded_by, graded_at, is_published, published_at, created_at, updated_at) FROM stdin;
1	6	26	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
2	6	20	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
3	6	15	missing	\N	ممتاز ي ذكي	32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
4	6	22	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
5	6	7	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
6	6	18	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
7	6	6	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
8	6	24	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
9	6	27	missing	\N		32	2026-03-25 00:19:23.480216+03	t	2026-03-25 00:19:25.955888+03	2026-03-25 00:19:23.480216+03	2026-03-25 00:19:25.955888+03
19	10	26	graded	1.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
20	10	20	graded	2.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
21	10	15	graded	3.00	جيد جدا	32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
22	10	22	graded	4.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
23	10	7	graded	5.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
24	10	18	graded	6.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
25	10	6	graded	7.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
26	10	24	graded	8.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
10	7	26	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
11	7	20	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
12	7	15	graded	10.00	شكرا ي ذكي 	32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
13	7	22	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
14	7	7	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
15	7	18	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
16	7	6	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
17	7	24	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
18	7	27	missing	\N		32	2026-03-25 00:28:49.584381+03	t	2026-03-25 00:28:49.637424+03	2026-03-25 00:28:47.168584+03	2026-03-25 00:28:49.637424+03
35	11	24	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
36	11	27	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
28	11	26	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
29	11	20	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
30	11	15	graded	10.00	ممتاز ي ولدي	32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
31	11	22	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
32	11	7	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
27	10	27	graded	9.00		32	2026-03-25 17:41:51.117533+03	t	2026-03-25 17:41:51.320171+03	2026-03-25 17:41:50.898967+03	2026-03-25 17:41:51.320171+03
33	11	18	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
34	11	6	missing	\N		32	2026-03-25 18:09:44.484489+03	t	2026-03-25 18:09:44.546885+03	2026-03-25 18:09:44.223095+03	2026-03-25 18:09:44.546885+03
37	12	26	graded	1.00	ممتاز 	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
38	12	20	graded	2.00	جيد	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
39	12	15	graded	3.00	جيد جدا	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
40	12	22	graded	4.00	احسنت	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
41	12	7	graded	5.00	بارك الله فيك	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
42	12	18	graded	6.00	احسنت ي ب طل	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
43	12	6	graded	7.00	انت طالب مجتهد	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
44	12	24	graded	8.00	انت مهما	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
45	12	27	graded	9.00	سيئ	32	2026-03-27 00:22:24.421873+03	t	2026-03-27 00:22:24.48704+03	2026-03-27 00:22:22.240341+03	2026-03-27 00:22:24.48704+03
46	16	26	graded	1.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
47	16	20	graded	2.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
48	16	15	graded	3.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
49	16	22	graded	4.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
50	16	7	graded	5.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
51	16	18	graded	6.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
52	16	6	graded	7.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
53	16	24	graded	8.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
54	16	27	graded	9.00		32	2026-03-27 18:00:09.776329+03	t	2026-03-27 18:00:09.863675+03	2026-03-27 18:00:09.776329+03	2026-03-27 18:00:09.863675+03
\.


--
-- Data for Name: assessment_reopen_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assessment_reopen_requests (id, assessment_id, requested_by_user_id, reason, status, admin_note, decided_by_user_id, decided_at, created_at) FROM stdin;
1	6	32	وجد خطا بالتصحيح زاريد مرجعة الدرجات لكي لا اظلم اي طالب	pending	\N	\N	\N	2026-03-25 00:23:16.204674+03
2	11	32	لاتلبا	pending	\N	\N	\N	2026-03-27 00:11:34.16749+03
\.


--
-- Data for Name: assessments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assessments (id, teacher_assignment_id, type, mode, status, title, description, max_score, starts_at, due_at, duration_minutes, late_policy_json, published_at, closed_at, created_at, updated_at, exam_kind, aggregate_kind, sequence_no, is_system_generated, source_assessment_ids, title_short) FROM stdin;
1	3	activity	in_class	published	نشاط	\N	10.00	2026-03-02 00:33:00+03	\N	\N	\N	2026-03-02 00:33:57.333033+03	\N	2026-03-02 00:33:33.567854+03	2026-03-02 00:33:57.333033+03	\N	\N	\N	f	\N	\N
2	3	homework	home_submission	published	نشاط  معنوي	\N	10.00	2026-03-24 23:01:00+03	2026-03-24 23:01:00+03	\N	{"late_until": null, "submission_kind": "text", "allow_late_submission": false}	2026-03-24 23:01:57.400031+03	\N	2026-03-24 23:01:57.35335+03	2026-03-24 23:01:57.400031+03	\N	\N	\N	f	\N	\N
3	3	homework	home_submission	published	نشاط	\N	10.00	2026-03-24 23:21:00+03	2026-03-24 23:21:00+03	\N	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": false}	2026-03-24 23:21:37.71971+03	\N	2026-03-24 23:21:37.682855+03	2026-03-24 23:21:37.71971+03	\N	\N	\N	f	\N	\N
4	3	homework	home_submission	published	نشاط	\N	10.00	2026-03-24 23:21:00+03	2026-03-24 23:21:00+03	\N	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": false}	2026-03-24 23:22:03.659533+03	\N	2026-03-24 23:22:03.635273+03	2026-03-24 23:22:03.659533+03	\N	\N	\N	f	\N	\N
6	3	homework	home_submission	closed	نشاط تقوية	عرف جميع المنهجيت	10.00	2026-03-25 00:03:00+03	2026-03-27 00:03:00+03	\N	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": false}	2026-03-25 00:04:26.365079+03	2026-03-25 00:19:25.955888+03	2026-03-25 00:04:26.341621+03	2026-03-25 00:19:25.955888+03	\N	\N	\N	f	\N	\N
7	3	homework	home_submission	closed	اسئلة على التضاريس	\N	10.00	2026-03-25 00:26:00+03	2026-03-28 00:26:00+03	\N	{"late_until": null, "submission_kind": "file", "allow_late_submission": false}	2026-03-25 00:26:57.840581+03	2026-03-25 00:28:49.637424+03	2026-03-25 00:26:57.809274+03	2026-03-25 00:28:49.637424+03	\N	\N	\N	f	\N	\N
8	3	classwork	in_class	closed	نشاط صفي	ارجو الاجابة على هذا السؤال فقط	10.00	\N	\N	20	{"late_until": null, "submission_kind": "none", "allow_late_submission": true}	2026-03-25 17:10:57.099222+03	2026-03-25 17:14:28.338548+03	2026-03-25 17:10:57.032238+03	2026-03-25 17:14:28.338548+03	\N	\N	\N	f	\N	\N
5	3	classwork	home_submission	closed	مسئلة	\N	10.00	2026-03-25 00:01:00+03	2026-03-25 00:01:00+03	\N	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": false}	2026-03-25 00:01:47.488299+03	2026-03-25 17:14:30.429104+03	2026-03-25 00:01:47.457083+03	2026-03-25 17:14:30.429104+03	\N	\N	\N	f	\N	\N
9	3	classwork	in_class	published	نشاط القوة والضعف	تعللموا	10.00	\N	\N	60	{"late_until": null, "submission_kind": "none", "allow_late_submission": true}	2026-03-25 17:21:25.979908+03	\N	2026-03-25 17:21:06.567809+03	2026-03-25 17:21:25.979908+03	\N	\N	\N	f	\N	\N
10	3	classwork	in_class	closed	تسميع سورة الكهف بالتجويد	\N	10.00	\N	\N	1	{"late_until": null, "submission_kind": "none", "allow_late_submission": true}	\N	2026-03-25 17:41:51.320171+03	2026-03-25 17:40:47.850776+03	2026-03-25 17:41:51.320171+03	\N	\N	\N	f	\N	\N
11	3	homework	home_submission	closed	واجب حل الوحدة رقم 50	\N	10.00	2026-03-25 17:55:00+03	2026-03-27 17:55:00+03	\N	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": true}	2026-03-25 17:56:20.934923+03	2026-03-25 18:09:44.546885+03	2026-03-25 17:56:20.828431+03	2026-03-25 18:09:44.546885+03	\N	\N	\N	f	\N	\N
12	3	classwork	in_class	published	نشاط املاء	\N	10.00	\N	\N	1	{"late_until": null, "submission_kind": "none", "allow_late_submission": true}	2026-03-27 00:22:24.48704+03	\N	2026-03-27 00:21:02.179599+03	2026-03-27 00:22:24.48704+03	\N	\N	\N	f	\N	نشاط املاء
13	3	homework	home_submission	closed	تحديد جديد	سبب نزول سورة البقرة	10.00	2026-03-27 00:30:00+03	2026-03-28 00:30:00+03	30	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": true}	2026-03-27 00:31:47.666664+03	2026-03-27 00:35:48.238233+03	2026-03-27 00:31:29.087984+03	2026-03-27 00:35:48.238233+03	\N	\N	\N	f	\N	تحديد جديد
14	3	homework	home_submission	published	املاء سورة الصافات	اجب على اسئلة الصفخة 17	10.00	2026-03-27 00:36:00+03	2026-03-27 00:36:00+03	30	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": true}	2026-03-27 00:37:12.041245+03	\N	2026-03-27 00:37:11.993839+03	2026-03-27 00:37:12.041245+03	\N	\N	\N	f	\N	املاء سورة الصافات
15	3	homework	home_submission	published	نشاط تقوية لطلابي الاقوياء	\N	10.00	2026-03-27 00:52:00+03	2026-03-27 00:52:00+03	20	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": true}	2026-03-27 00:52:43.273475+03	\N	2026-03-27 00:52:43.222463+03	2026-03-27 00:52:43.273475+03	\N	\N	\N	f	\N	نشاط تقوية لطلابي الاقوياء
16	3	homework	home_submission	published	عدد انواع  التلوث	\N	10.00	2026-03-27 17:59:00+03	2026-03-28 17:59:00+03	30	{"late_until": null, "submission_kind": "mixed", "allow_late_submission": true}	2026-03-27 17:59:54.010848+03	\N	2026-03-27 17:59:53.953701+03	2026-03-27 18:00:09.863675+03	\N	\N	\N	f	\N	عدد انواع  التلوث
\.


--
-- Data for Name: attendance_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance_entries (id, session_id, student_id, status, reason_id, late_minutes, note, created_at, updated_at) FROM stdin;
1	1	7	present	\N	\N	\N	2026-01-24 22:51:05.620314+03	2026-01-24 22:51:05.620314+03
2	1	6	present	\N	\N	\N	2026-01-24 22:51:05.620314+03	2026-01-24 22:51:05.620314+03
3	1	18	present	\N	\N	\N	2026-01-24 22:51:05.620314+03	2026-01-24 22:51:05.620314+03
4	1	20	present	\N	\N	\N	2026-01-24 22:51:05.620314+03	2026-01-24 22:51:05.620314+03
5	2	7	present	\N	\N	\N	2026-01-24 23:10:03.607622+03	2026-01-24 23:10:03.607622+03
6	2	6	present	\N	\N	\N	2026-01-24 23:10:03.607622+03	2026-01-24 23:10:03.607622+03
7	2	18	present	\N	\N	\N	2026-01-24 23:10:03.607622+03	2026-01-24 23:10:03.607622+03
8	2	20	present	\N	\N	\N	2026-01-24 23:10:03.607622+03	2026-01-24 23:10:03.607622+03
12	3	20	absent	\N	\N	\N	2026-01-24 23:21:34.455135+03	2026-01-24 23:22:29.087493+03
9	3	7	absent	\N	\N	\N	2026-01-24 23:21:34.455135+03	2026-01-24 23:22:29.087493+03
10	3	6	absent	\N	\N	\N	2026-01-24 23:21:34.455135+03	2026-01-24 23:22:29.087493+03
11	3	18	absent	\N	\N	\N	2026-01-24 23:21:34.455135+03	2026-01-24 23:22:29.087493+03
16	4	20	absent	\N	\N	\N	2026-01-25 00:46:50.802322+03	2026-01-25 00:47:24.613804+03
13	4	7	absent	\N	\N	\N	2026-01-25 00:46:50.802322+03	2026-01-25 00:47:24.613804+03
14	4	6	absent	\N	\N	\N	2026-01-25 00:46:50.802322+03	2026-01-25 00:47:24.613804+03
15	4	18	absent	\N	\N	\N	2026-01-25 00:46:50.802322+03	2026-01-25 00:47:24.613804+03
52	13	20	present	\N	\N	\N	2026-01-28 16:40:50.160554+03	2026-01-28 16:40:58.048477+03
49	13	7	present	\N	\N	\N	2026-01-28 16:40:50.160554+03	2026-01-28 16:40:58.048477+03
50	13	6	present	\N	\N	\N	2026-01-28 16:40:50.160554+03	2026-01-28 16:40:58.048477+03
51	13	18	present	\N	\N	\N	2026-01-28 16:40:50.160554+03	2026-01-28 16:40:58.048477+03
20	5	20	present	\N	\N	\N	2026-01-25 17:36:22.394498+03	2026-01-25 17:37:00.911097+03
17	5	7	present	\N	\N	\N	2026-01-25 17:36:22.394498+03	2026-01-25 17:37:00.911097+03
18	5	6	present	\N	\N	\N	2026-01-25 17:36:22.394498+03	2026-01-25 17:37:00.911097+03
19	5	18	present	\N	\N	\N	2026-01-25 17:36:22.394498+03	2026-01-25 17:37:00.911097+03
21	6	7	present	\N	\N	\N	2026-01-26 01:22:53.897783+03	2026-01-26 01:22:53.897783+03
22	6	6	present	\N	\N	\N	2026-01-26 01:22:53.897783+03	2026-01-26 01:22:53.897783+03
23	6	18	present	\N	\N	\N	2026-01-26 01:22:53.897783+03	2026-01-26 01:22:53.897783+03
24	6	20	present	\N	\N	\N	2026-01-26 01:22:53.897783+03	2026-01-26 01:22:53.897783+03
25	7	7	present	\N	\N	\N	2026-01-26 23:57:49.954091+03	2026-01-26 23:57:49.954091+03
26	7	6	present	\N	\N	\N	2026-01-26 23:57:49.954091+03	2026-01-26 23:57:49.954091+03
27	7	18	present	\N	\N	\N	2026-01-26 23:57:49.954091+03	2026-01-26 23:57:49.954091+03
28	7	20	present	\N	\N	\N	2026-01-26 23:57:49.954091+03	2026-01-26 23:57:49.954091+03
29	8	7	present	\N	\N	\N	2026-01-27 16:41:18.449476+03	2026-01-27 16:41:18.449476+03
30	8	6	present	\N	\N	\N	2026-01-27 16:41:18.449476+03	2026-01-27 16:41:18.449476+03
31	8	18	present	\N	\N	\N	2026-01-27 16:41:18.449476+03	2026-01-27 16:41:18.449476+03
32	8	20	present	\N	\N	\N	2026-01-27 16:41:18.449476+03	2026-01-27 16:41:18.449476+03
33	9	7	present	\N	\N	\N	2026-01-28 00:59:48.103206+03	2026-01-28 00:59:48.103206+03
34	9	6	present	\N	\N	\N	2026-01-28 00:59:48.103206+03	2026-01-28 00:59:48.103206+03
35	9	18	present	\N	\N	\N	2026-01-28 00:59:48.103206+03	2026-01-28 00:59:48.103206+03
36	9	20	present	\N	\N	\N	2026-01-28 00:59:48.103206+03	2026-01-28 00:59:48.103206+03
40	10	20	present	\N	\N	\N	2026-01-28 15:20:04.293755+03	2026-01-28 15:20:06.572082+03
37	10	7	present	\N	\N	\N	2026-01-28 15:20:04.293755+03	2026-01-28 15:20:06.572082+03
38	10	6	present	\N	\N	\N	2026-01-28 15:20:04.293755+03	2026-01-28 15:20:06.572082+03
39	10	18	present	\N	\N	\N	2026-01-28 15:20:04.293755+03	2026-01-28 15:20:06.572082+03
44	11	20	present	\N	\N	\N	2026-01-28 16:10:40.133936+03	2026-01-28 16:10:41.911626+03
41	11	7	present	\N	\N	\N	2026-01-28 16:10:40.133936+03	2026-01-28 16:10:41.911626+03
42	11	6	present	\N	\N	\N	2026-01-28 16:10:40.133936+03	2026-01-28 16:10:41.911626+03
43	11	18	present	\N	\N	\N	2026-01-28 16:10:40.133936+03	2026-01-28 16:10:41.911626+03
48	12	20	absent	4	\N	\N	2026-01-28 16:11:38.914127+03	2026-01-28 16:12:06.27216+03
45	12	7	absent	2	\N	\N	2026-01-28 16:11:38.914127+03	2026-01-28 16:12:06.27216+03
46	12	6	absent	1	\N	\N	2026-01-28 16:11:38.914127+03	2026-01-28 16:12:06.27216+03
47	12	18	absent	3	\N	\N	2026-01-28 16:11:38.914127+03	2026-01-28 16:12:06.27216+03
76	19	20	present	\N	\N	\N	2026-02-02 00:35:59.294165+03	2026-02-02 00:36:02.836896+03
56	14	20	present	\N	\N	\N	2026-01-29 01:04:51.930094+03	2026-01-29 01:07:29.736895+03
53	14	7	present	\N	\N	\N	2026-01-29 01:04:51.930094+03	2026-01-29 01:07:29.736895+03
54	14	6	present	\N	\N	\N	2026-01-29 01:04:51.930094+03	2026-01-29 01:07:29.736895+03
55	14	18	present	\N	\N	\N	2026-01-29 01:04:51.930094+03	2026-01-29 01:07:29.736895+03
73	19	7	present	\N	\N	\N	2026-02-02 00:35:59.294165+03	2026-02-02 00:36:02.836896+03
68	17	20	present	\N	\N	\N	2026-02-01 23:09:05.970662+03	2026-02-01 23:09:37.333632+03
65	17	7	late	\N	60	\N	2026-02-01 23:09:05.970662+03	2026-02-01 23:09:37.333632+03
60	15	20	present	\N	\N	\N	2026-01-31 15:20:26.000012+03	2026-01-31 15:28:54.772855+03
57	15	7	present	\N	\N	\N	2026-01-31 15:20:26.000012+03	2026-01-31 15:28:54.772855+03
58	15	6	present	\N	\N	\N	2026-01-31 15:20:26.000012+03	2026-01-31 15:28:54.772855+03
59	15	18	present	\N	\N	\N	2026-01-31 15:20:26.000012+03	2026-01-31 15:28:54.772855+03
61	16	7	present	\N	\N	\N	2026-01-31 17:04:41.132755+03	2026-01-31 17:04:41.132755+03
62	16	6	present	\N	\N	\N	2026-01-31 17:04:41.132755+03	2026-01-31 17:04:41.132755+03
63	16	18	present	\N	\N	\N	2026-01-31 17:04:41.132755+03	2026-01-31 17:04:41.132755+03
64	16	20	present	\N	\N	\N	2026-01-31 17:04:41.132755+03	2026-01-31 17:04:41.132755+03
67	17	18	excused	3	\N	\N	2026-02-01 23:09:05.970662+03	2026-02-01 23:09:37.333632+03
66	17	6	present	\N	\N	\N	2026-02-01 23:09:05.970662+03	2026-02-01 23:09:37.333632+03
72	18	20	present	\N	\N	\N	2026-02-01 23:47:55.281818+03	2026-02-02 00:35:20.852276+03
69	18	7	present	\N	\N	\N	2026-02-01 23:47:55.281818+03	2026-02-02 00:35:20.852276+03
70	18	6	present	\N	\N	\N	2026-02-01 23:47:55.281818+03	2026-02-02 00:35:20.852276+03
71	18	18	present	\N	\N	\N	2026-02-01 23:47:55.281818+03	2026-02-02 00:35:20.852276+03
74	19	6	present	\N	\N	\N	2026-02-02 00:35:59.294165+03	2026-02-02 00:36:02.836896+03
75	19	18	present	\N	\N	\N	2026-02-02 00:35:59.294165+03	2026-02-02 00:36:02.836896+03
77	20	7	present	\N	\N	\N	2026-02-02 01:36:16.100055+03	2026-02-02 01:36:16.100055+03
78	20	6	present	\N	\N	\N	2026-02-02 01:36:16.100055+03	2026-02-02 01:36:16.100055+03
79	20	18	present	\N	\N	\N	2026-02-02 01:36:16.100055+03	2026-02-02 01:36:16.100055+03
80	20	20	present	\N	\N	\N	2026-02-02 01:36:16.100055+03	2026-02-02 01:36:16.100055+03
81	21	21	absent	2	\N	\N	2026-02-02 16:27:21.649+03	2026-02-02 16:27:49.088492+03
85	22	20	present	\N	\N	\N	2026-02-02 17:04:33.761636+03	2026-02-02 17:06:38.850843+03
82	22	7	present	\N	\N	\N	2026-02-02 17:04:33.761636+03	2026-02-02 17:06:38.850843+03
83	22	6	present	\N	\N	\N	2026-02-02 17:04:33.761636+03	2026-02-02 17:06:38.850843+03
84	22	18	present	\N	\N	\N	2026-02-02 17:04:33.761636+03	2026-02-02 17:06:38.850843+03
89	23	20	present	\N	\N	\N	2026-02-02 17:07:14.496465+03	2026-02-02 17:07:19.856178+03
86	23	7	present	\N	\N	\N	2026-02-02 17:07:14.496465+03	2026-02-02 17:07:19.856178+03
87	23	6	present	\N	\N	\N	2026-02-02 17:07:14.496465+03	2026-02-02 17:07:19.856178+03
88	23	18	present	\N	\N	\N	2026-02-02 17:07:14.496465+03	2026-02-02 17:07:19.856178+03
93	24	20	present	\N	\N	\N	2026-02-02 17:09:43.162944+03	2026-02-02 17:12:22.789001+03
90	24	7	present	\N	\N	\N	2026-02-02 17:09:43.162944+03	2026-02-02 17:12:22.789001+03
91	24	6	present	\N	\N	\N	2026-02-02 17:09:43.162944+03	2026-02-02 17:12:22.789001+03
92	24	18	excused	\N	\N	إذن غياب مقبول	2026-02-02 17:09:43.162944+03	2026-02-02 17:12:22.789001+03
97	25	20	absent	1	\N	\N	2026-02-02 17:39:50.234804+03	2026-02-02 17:57:30.303005+03
94	25	7	absent	1	\N	\N	2026-02-02 17:39:50.234804+03	2026-02-02 17:57:30.303005+03
95	25	6	absent	3	\N	\N	2026-02-02 17:39:50.234804+03	2026-02-02 17:57:30.303005+03
96	25	18	excused	5	\N	(إذن إلكتروني: ABSENCE)	2026-02-02 17:39:50.234804+03	2026-02-02 17:57:30.303005+03
101	26	20	present	\N	\N	\N	2026-02-04 22:51:35.33458+03	2026-02-05 01:01:11.4644+03
98	26	7	present	\N	\N	\N	2026-02-04 22:51:35.33458+03	2026-02-05 01:01:11.4644+03
99	26	6	present	\N	\N	\N	2026-02-04 22:51:35.33458+03	2026-02-05 01:01:11.4644+03
100	26	18	present	\N	\N	(إذن إلكتروني: ABSENCE)	2026-02-04 22:51:35.33458+03	2026-02-05 01:01:11.4644+03
105	27	20	excused	\N	\N	(إذن إلكتروني: ABSENCE)	2026-02-05 01:01:18.220109+03	2026-02-05 01:06:50.136446+03
102	27	7	present	\N	\N	\N	2026-02-05 01:01:18.220109+03	2026-02-05 01:06:50.136446+03
103	27	6	present	\N	\N	\N	2026-02-05 01:01:18.220109+03	2026-02-05 01:06:50.136446+03
104	27	18	excused	\N	\N	(إذن إلكتروني: ABSENCE)	2026-02-05 01:01:18.220109+03	2026-02-05 01:06:50.136446+03
106	28	17	present	\N	\N	\N	2026-02-05 01:11:46.583212+03	2026-02-05 22:40:42.689077+03
107	29	21	excused	\N	\N	(إذن إلكتروني)	2026-02-05 22:48:16.03443+03	2026-02-06 00:04:12.395293+03
182	45	7	absent	1	\N	\N	2026-02-24 22:03:28.294967+03	2026-02-24 22:04:05.101824+03
180	43	23	excused	\N	\N	(إذن مقبول)	2026-02-21 21:34:27.832784+03	2026-02-21 21:35:06.552631+03
153	39	22	present	\N	\N	[QR] تم تسجيل الحضور عبر المسح	2026-02-13 17:03:10.124677+03	2026-02-13 18:11:31.625043+03
111	30	20	present	\N	\N	\N	2026-02-07 14:17:35.003871+03	2026-02-07 14:19:52.667513+03
108	30	7	present	\N	\N	\N	2026-02-07 14:17:35.003871+03	2026-02-07 14:19:52.667513+03
109	30	6	present	\N	\N	\N	2026-02-07 14:17:35.003871+03	2026-02-07 14:19:52.667513+03
110	30	18	present	\N	\N	\N	2026-02-07 14:17:35.003871+03	2026-02-07 14:19:52.667513+03
136	37	20	present	\N	\N	\N	2026-02-11 23:11:32.749494+03	2026-02-11 23:30:20.497357+03
133	37	7	present	\N	\N	\N	2026-02-11 23:11:32.749494+03	2026-02-11 23:30:20.497357+03
134	37	6	present	\N	\N	\N	2026-02-11 23:11:32.749494+03	2026-02-11 23:30:20.497357+03
135	37	18	present	\N	\N	\N	2026-02-11 23:11:32.749494+03	2026-02-11 23:30:20.497357+03
115	31	20	present	\N	\N	\N	2026-02-07 16:08:25.518158+03	2026-02-07 16:10:51.247094+03
112	31	7	present	\N	\N	\N	2026-02-07 16:08:25.518158+03	2026-02-07 16:10:51.247094+03
113	31	6	present	\N	\N	\N	2026-02-07 16:08:25.518158+03	2026-02-07 16:10:51.247094+03
114	31	18	present	\N	\N	\N	2026-02-07 16:08:25.518158+03	2026-02-07 16:10:51.247094+03
137	38	7	present	\N	\N	\N	2026-02-11 23:30:38.944964+03	2026-02-11 23:30:38.944964+03
138	38	6	present	\N	\N	\N	2026-02-11 23:30:38.944964+03	2026-02-11 23:30:38.944964+03
139	38	18	present	\N	\N	\N	2026-02-11 23:30:38.944964+03	2026-02-11 23:30:38.944964+03
140	38	20	present	\N	\N	\N	2026-02-11 23:30:38.944964+03	2026-02-11 23:30:38.944964+03
116	32	21	absent	\N	\N	(إذن مرفوض)	2026-02-07 17:32:47.748362+03	2026-02-07 17:53:36.289656+03
141	38	22	present	\N	\N	[QR] تم تسجيل الحضور عبر المسح	2026-02-11 23:30:38.944964+03	2026-02-12 01:28:15.60639+03
149	39	7	present	\N	\N	\N	2026-02-13 17:03:10.124677+03	2026-02-13 17:03:10.124677+03
150	39	6	present	\N	\N	\N	2026-02-13 17:03:10.124677+03	2026-02-13 17:03:10.124677+03
151	39	18	present	\N	\N	\N	2026-02-13 17:03:10.124677+03	2026-02-13 17:03:10.124677+03
152	39	20	present	\N	\N	\N	2026-02-13 17:03:10.124677+03	2026-02-13 17:03:10.124677+03
120	33	20	present	\N	\N	\N	2026-02-08 14:50:27.471365+03	2026-02-08 15:01:18.777834+03
117	33	7	present	\N	\N	\N	2026-02-08 14:50:27.471365+03	2026-02-08 15:01:18.777834+03
118	33	6	present	\N	\N	\N	2026-02-08 14:50:27.471365+03	2026-02-08 15:01:18.777834+03
119	33	18	present	\N	\N	\N	2026-02-08 14:50:27.471365+03	2026-02-08 15:01:18.777834+03
124	34	20	present	\N	\N	\N	2026-02-08 15:02:23.501104+03	2026-02-08 15:02:25.850575+03
121	34	7	present	\N	\N	\N	2026-02-08 15:02:23.501104+03	2026-02-08 15:02:25.850575+03
122	34	6	present	\N	\N	\N	2026-02-08 15:02:23.501104+03	2026-02-08 15:02:25.850575+03
123	34	18	present	\N	\N	\N	2026-02-08 15:02:23.501104+03	2026-02-08 15:02:25.850575+03
128	35	20	present	\N	\N	\N	2026-02-08 15:02:37.637758+03	2026-02-08 15:02:38.233702+03
125	35	7	present	\N	\N	\N	2026-02-08 15:02:37.637758+03	2026-02-08 15:02:38.233702+03
126	35	6	present	\N	\N	\N	2026-02-08 15:02:37.637758+03	2026-02-08 15:02:38.233702+03
127	35	18	present	\N	\N	\N	2026-02-08 15:02:37.637758+03	2026-02-08 15:02:38.233702+03
132	36	20	present	\N	\N	\N	2026-02-09 17:35:23.00422+03	2026-02-09 17:58:01.006235+03
129	36	7	present	\N	\N	\N	2026-02-09 17:35:23.00422+03	2026-02-09 17:58:01.006235+03
130	36	6	present	\N	\N	\N	2026-02-09 17:35:23.00422+03	2026-02-09 17:58:01.006235+03
131	36	18	present	\N	\N	\N	2026-02-09 17:35:23.00422+03	2026-02-09 17:58:01.006235+03
166	40	20	present	\N	\N	\N	2026-02-14 14:36:04.090742+03	2026-02-14 14:37:05.993658+03
167	40	22	present	\N	\N	[QR] تم تسجيل الحضور عبر المسح	2026-02-14 14:36:04.090742+03	2026-02-14 14:37:05.993658+03
163	40	7	present	\N	\N	\N	2026-02-14 14:36:04.090742+03	2026-02-14 14:37:05.993658+03
164	40	6	present	\N	\N	\N	2026-02-14 14:36:04.090742+03	2026-02-14 14:37:05.993658+03
183	45	6	absent	5	\N	\N	2026-02-24 22:03:28.294967+03	2026-02-24 22:04:05.101824+03
165	40	18	present	\N	\N	\N	2026-02-14 14:36:04.090742+03	2026-02-14 14:37:05.993658+03
169	41	7	present	\N	\N	\N	2026-02-14 14:37:11.133956+03	2026-02-14 14:37:11.133956+03
170	41	6	present	\N	\N	\N	2026-02-14 14:37:11.133956+03	2026-02-14 14:37:11.133956+03
171	41	18	present	\N	\N	\N	2026-02-14 14:37:11.133956+03	2026-02-14 14:37:11.133956+03
172	41	20	present	\N	\N	\N	2026-02-14 14:37:11.133956+03	2026-02-14 14:37:11.133956+03
173	41	22	present	\N	\N	[QR] تم تسجيل الحضور عبر المسح	2026-02-14 14:37:11.133956+03	2026-02-14 14:37:47.446379+03
181	44	21	present	\N	\N	\N	2026-02-21 21:36:58.215073+03	2026-02-21 21:37:10.666136+03
185	45	20	present	\N	\N	\N	2026-02-24 22:03:28.294967+03	2026-02-24 22:04:05.101824+03
186	45	22	absent	1	\N	\N	2026-02-24 22:03:28.294967+03	2026-02-24 22:04:05.101824+03
184	45	18	absent	4	\N	\N	2026-02-24 22:03:28.294967+03	2026-02-24 22:04:05.101824+03
190	46	20	absent	1	\N	\N	2026-02-24 22:25:49.223987+03	2026-02-24 22:26:09.786147+03
191	46	22	absent	2	\N	\N	2026-02-24 22:25:49.223987+03	2026-02-24 22:26:09.786147+03
187	46	7	absent	2	\N	\N	2026-02-24 22:25:49.223987+03	2026-02-24 22:26:09.786147+03
188	46	6	absent	5	\N	\N	2026-02-24 22:25:49.223987+03	2026-02-24 22:26:09.786147+03
189	46	18	absent	5	\N	\N	2026-02-24 22:25:49.223987+03	2026-02-24 22:26:09.786147+03
195	47	20	present	\N	\N	\N	2026-02-25 22:47:17.068924+03	2026-02-25 22:47:18.551326+03
196	47	22	present	\N	\N	\N	2026-02-25 22:47:17.068924+03	2026-02-25 22:47:18.551326+03
192	47	7	present	\N	\N	\N	2026-02-25 22:47:17.068924+03	2026-02-25 22:47:18.551326+03
193	47	6	present	\N	\N	\N	2026-02-25 22:47:17.068924+03	2026-02-25 22:47:18.551326+03
194	47	18	present	\N	\N	\N	2026-02-25 22:47:17.068924+03	2026-02-25 22:47:18.551326+03
\.


--
-- Data for Name: attendance_entry_corrections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance_entry_corrections (id, session_id, student_id, corrected_status, corrected_reason_id, corrected_late_minutes, corrected_note, correction_reason, corrected_by_user_id, created_at, permission_request_id) FROM stdin;
2	5	20	absent	\N	\N	\N	يلعب	32	2026-01-25 17:52:52.077131+03	\N
3	8	20	absent	\N	\N	\N	تم	32	2026-01-27 16:42:04.078164+03	\N
4	17	7	late	1	60	النوم	مرض	32	2026-02-01 23:10:05.441187+03	\N
\.


--
-- Data for Name: attendance_reasons; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance_reasons (id, name, is_active, created_at) FROM stdin;
1	مرض	t	2026-01-16 14:54:52.971126+03
2	سفر	t	2026-01-16 14:54:52.971126+03
3	ظرف عائلي	t	2026-01-16 14:54:52.971126+03
4	بدون عذر	t	2026-01-16 14:54:52.971126+03
5	أخرى	t	2026-01-16 14:54:52.971126+03
\.


--
-- Data for Name: attendance_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance_sessions (id, academic_year_id, term, attendance_date, period_id, section_id, subject_id, teacher_id, created_by, is_locked, created_at, updated_at, locked_at, locked_by, started_at, ended_at, lesson_note, source, notes, stage_id, grade_id, duration_seconds) FROM stdin;
31	1	1	2026-02-07	2	1	9	1	\N	t	2026-02-07 16:08:25.518158+03	2026-02-07 16:10:51.247094+03	\N	\N	2026-02-07 16:08:25.518158+03	2026-02-07 16:10:51.247094+03	\N	manual	\N	\N	\N	\N
6	1	1	2026-01-25	3	1	9	1	\N	t	2026-01-26 01:22:53.897783+03	2026-01-26 01:22:56.325955+03	\N	\N	2026-01-26 01:22:53.897783+03	2026-01-26 01:22:56.325955+03	\N	manual	\N	\N	\N	\N
22	1	1	2026-02-02	1	1	9	1	\N	t	2026-02-02 17:04:33.761636+03	2026-02-02 17:06:38.850843+03	\N	\N	2026-02-02 17:04:33.761636+03	2026-02-02 17:06:38.850843+03	\N	manual	\N	\N	\N	\N
7	1	1	2026-01-26	1	1	9	1	\N	t	2026-01-26 23:57:49.954091+03	2026-01-26 23:58:46.936679+03	\N	\N	2026-01-26 23:57:49.954091+03	2026-01-26 23:58:46.936679+03	\N	manual	\N	\N	\N	\N
32	1	1	2026-02-07	10	23	2	1	\N	f	2026-02-07 17:32:47.748362+03	2026-02-07 17:32:47.748362+03	\N	\N	2026-02-07 17:32:47.748362+03	\N	\N	manual	\N	\N	\N	\N
8	1	1	2026-01-27	1	1	9	1	\N	t	2026-01-27 16:41:18.449476+03	2026-01-27 16:41:32.09906+03	\N	\N	2026-01-27 16:41:18.449476+03	2026-01-27 16:41:32.09906+03	\N	manual	\N	\N	\N	\N
23	1	1	2026-02-02	2	1	9	1	\N	t	2026-02-02 17:07:14.496465+03	2026-02-02 17:07:19.856178+03	\N	\N	2026-02-02 17:07:14.496465+03	2026-02-02 17:07:19.856178+03	\N	manual	\N	\N	\N	\N
9	1	1	2026-01-27	2	1	9	1	\N	t	2026-01-28 00:59:48.103206+03	2026-01-28 01:00:01.235453+03	\N	\N	2026-01-28 00:59:48.103206+03	2026-01-28 01:00:01.235453+03	\N	manual	\N	\N	\N	\N
47	1	1	2026-02-25	1	1	9	1	\N	t	2026-02-25 22:47:17.068924+03	2026-02-25 22:47:18.551326+03	2026-02-25 22:47:18.551326+03	32	2026-02-25 22:47:17.068924+03	2026-02-25 22:47:18.551326+03	\N	manual	\N	\N	\N	\N
10	1	1	2026-01-28	1	1	9	1	\N	t	2026-01-28 15:20:04.293755+03	2026-01-28 15:20:06.572082+03	\N	\N	2026-01-28 15:20:04.293755+03	2026-01-28 15:20:06.572082+03	\N	manual	\N	\N	\N	\N
33	1	1	2026-02-08	1	1	9	1	\N	t	2026-02-08 14:50:27.471365+03	2026-02-08 15:01:18.777834+03	2026-02-08 15:01:18.777834+03	32	2026-02-08 14:50:27.471365+03	2026-02-08 15:01:18.777834+03	\N	manual	\N	\N	\N	\N
11	1	1	2026-01-28	3	1	9	1	\N	t	2026-01-28 16:10:40.133936+03	2026-01-28 16:10:41.911626+03	\N	\N	2026-01-28 16:10:40.133936+03	2026-01-28 16:10:41.911626+03	\N	manual	\N	\N	\N	\N
2	1	1	2026-01-24	2	1	9	1	\N	t	2026-01-24 23:10:03.607622+03	2026-01-24 23:10:22.188943+03	\N	\N	2026-01-24 23:10:03.607622+03	2026-01-24 23:10:22.188943+03	\N	manual	\N	\N	\N	\N
24	1	1	2026-02-02	3	1	9	1	\N	t	2026-02-02 17:09:43.162944+03	2026-02-02 17:12:35.964975+03	\N	\N	2026-02-02 17:09:43.162944+03	2026-02-02 17:12:22.789001+03	\N	manual	\N	\N	\N	\N
1	1	1	2026-01-24	1	1	9	1	\N	t	2026-01-24 22:51:05.620314+03	2026-01-24 23:21:16.471142+03	\N	\N	2026-01-24 22:51:05.620314+03	2026-01-24 22:51:05.733215+03	\N	manual	\N	\N	\N	\N
3	1	1	2026-01-24	21	1	9	1	\N	t	2026-01-24 23:21:34.455135+03	2026-01-24 23:22:29.087493+03	\N	\N	\N	2026-01-24 23:22:29.087493+03	\N	manual	\N	\N	\N	\N
12	1	1	2026-01-28	10	1	9	1	\N	t	2026-01-28 16:11:38.914127+03	2026-01-28 16:12:06.27216+03	\N	\N	2026-01-28 16:11:38.914127+03	2026-01-28 16:12:06.27216+03	\N	manual	\N	\N	\N	\N
4	1	1	2026-01-24	3	1	9	1	\N	t	2026-01-25 00:46:50.802322+03	2026-01-25 00:47:24.613804+03	\N	\N	2026-01-25 00:46:50.802322+03	2026-01-25 00:47:24.613804+03	\N	manual	\N	\N	\N	\N
41	1	1	2026-02-14	2	1	9	1	\N	f	2026-02-14 14:37:11.133956+03	2026-02-14 23:16:22.92286+03	\N	\N	2026-02-14 14:37:11.133956+03	\N	\N	manual	\N	\N	\N	\N
13	1	1	2026-01-28	11	1	9	1	\N	t	2026-01-28 16:40:50.160554+03	2026-01-28 16:40:58.048477+03	\N	\N	2026-01-28 16:40:50.160554+03	2026-01-28 16:40:58.048477+03	\N	manual	\N	\N	\N	\N
34	1	1	2026-02-08	3	1	9	1	\N	t	2026-02-08 15:02:23.501104+03	2026-02-08 15:02:25.850575+03	2026-02-08 15:02:25.850575+03	32	2026-02-08 15:02:23.501104+03	2026-02-08 15:02:25.850575+03	\N	manual	\N	\N	\N	\N
25	1	1	2026-02-02	8	1	9	1	\N	t	2026-02-02 17:39:50.234804+03	2026-02-02 17:58:02.649394+03	\N	\N	2026-02-02 17:39:50.234804+03	2026-02-02 17:57:30.303005+03	\N	manual	\N	\N	\N	\N
14	1	1	2026-01-28	8	1	9	1	\N	t	2026-01-29 01:04:51.930094+03	2026-01-29 01:07:35.877262+03	\N	\N	2026-01-29 01:04:51.930094+03	2026-01-29 01:07:29.736895+03	\N	manual	\N	\N	\N	\N
15	1	1	2026-01-31	1	1	9	1	\N	t	2026-01-31 15:20:26.000012+03	2026-01-31 15:28:54.772855+03	\N	\N	2026-01-31 15:20:26.000012+03	2026-01-31 15:28:54.772855+03	\N	manual	\N	\N	\N	\N
16	1	1	2026-01-31	2	1	9	1	\N	f	2026-01-31 17:04:41.132755+03	2026-01-31 17:04:41.132755+03	\N	\N	2026-01-31 17:04:41.132755+03	\N	\N	manual	\N	\N	\N	\N
35	1	1	2026-02-08	8	1	9	1	\N	t	2026-02-08 15:02:37.637758+03	2026-02-08 15:02:38.233702+03	2026-02-08 15:02:38.233702+03	32	2026-02-08 15:02:37.637758+03	2026-02-08 15:02:38.233702+03	\N	manual	\N	\N	\N	\N
5	1	1	2026-01-25	1	1	9	1	\N	t	2026-01-25 17:36:22.394498+03	2026-01-26 00:08:32.495109+03	\N	\N	2026-01-25 17:36:22.394498+03	2026-01-25 17:37:00.911097+03	\N	manual	\N	\N	\N	\N
17	1	1	2026-02-01	1	1	9	1	\N	t	2026-02-01 23:09:05.970662+03	2026-02-01 23:09:37.333632+03	\N	\N	2026-02-01 23:09:05.970662+03	2026-02-01 23:09:37.333632+03	\N	manual	\N	\N	\N	\N
26	1	1	2026-02-04	1	1	9	1	\N	t	2026-02-04 22:51:35.33458+03	2026-02-05 01:01:15.373025+03	\N	\N	2026-02-04 22:51:35.33458+03	2026-02-05 01:01:11.4644+03	\N	manual	\N	\N	\N	\N
18	1	1	2026-02-01	3	1	9	1	\N	t	2026-02-01 23:47:55.281818+03	2026-02-02 00:35:20.852276+03	\N	\N	2026-02-01 23:47:55.281818+03	2026-02-02 00:35:20.852276+03	\N	manual	\N	\N	\N	\N
43	1	1	2026-02-21	35	28	9	1	\N	t	2026-02-21 21:34:27.832784+03	2026-02-21 21:35:06.552631+03	2026-02-21 21:35:06.552631+03	32	2026-02-21 21:34:27.832784+03	2026-02-21 21:35:06.552631+03	\N	manual	\N	\N	\N	\N
19	1	1	2026-02-01	8	1	9	1	\N	t	2026-02-02 00:35:59.294165+03	2026-02-02 00:36:02.836896+03	\N	\N	2026-02-02 00:35:59.294165+03	2026-02-02 00:36:02.836896+03	\N	manual	\N	\N	\N	\N
20	1	1	2026-02-01	9	1	2	13	\N	f	2026-02-02 01:36:16.100055+03	2026-02-02 01:36:16.100055+03	\N	\N	2026-02-02 01:36:16.100055+03	\N	\N	manual	\N	\N	\N	\N
27	1	1	2026-02-04	3	1	9	1	\N	t	2026-02-05 01:01:18.220109+03	2026-02-05 01:06:50.136446+03	\N	\N	2026-02-05 01:01:18.220109+03	2026-02-05 01:06:50.136446+03	\N	manual	\N	\N	\N	\N
21	1	1	2026-02-02	35	23	15	1	\N	t	2026-02-02 16:27:21.649+03	2026-02-02 16:27:49.088492+03	\N	\N	2026-02-02 16:27:21.649+03	2026-02-02 16:27:49.088492+03	\N	manual	\N	\N	\N	\N
36	1	1	2026-02-09	1	1	9	1	\N	t	2026-02-09 17:35:23.00422+03	2026-02-09 17:58:01.006235+03	2026-02-09 17:58:01.006235+03	32	2026-02-09 17:35:23.00422+03	2026-02-09 17:58:01.006235+03	\N	manual	\N	\N	\N	\N
28	1	1	2026-02-04	21	4	15	1	\N	t	2026-02-05 01:11:46.583212+03	2026-02-05 22:40:42.689077+03	\N	\N	2026-02-05 01:11:46.583212+03	2026-02-05 22:40:42.689077+03	\N	manual	\N	\N	\N	\N
29	1	1	2026-02-05	1	23	9	1	\N	t	2026-02-05 22:48:16.03443+03	2026-02-06 00:04:12.395293+03	\N	\N	2026-02-05 22:48:16.03443+03	2026-02-06 00:04:12.395293+03	\N	manual	\N	\N	\N	\N
37	1	1	2026-02-11	1	1	9	1	\N	t	2026-02-11 23:11:32.749494+03	2026-02-11 23:30:20.497357+03	2026-02-11 23:30:20.497357+03	32	2026-02-11 23:11:32.749494+03	2026-02-11 23:30:20.497357+03	\N	manual	\N	\N	\N	\N
30	1	1	2026-02-07	1	1	9	1	\N	t	2026-02-07 14:17:35.003871+03	2026-02-07 14:19:52.667513+03	\N	\N	2026-02-07 14:17:35.003871+03	2026-02-07 14:19:52.667513+03	\N	manual	\N	\N	\N	\N
44	1	1	2026-02-21	10	23	2	1	\N	t	2026-02-21 21:36:58.215073+03	2026-02-21 21:37:10.666136+03	2026-02-21 21:37:10.666136+03	32	2026-02-21 21:36:58.215073+03	2026-02-21 21:37:10.666136+03	\N	manual	\N	\N	\N	\N
38	1	1	2026-02-11	3	1	9	1	\N	f	2026-02-11 23:30:38.944964+03	2026-02-11 23:30:38.944964+03	\N	\N	2026-02-11 23:30:38.944964+03	\N	\N	manual	\N	\N	\N	\N
39	1	1	2026-02-13	1	1	9	1	\N	f	2026-02-13 17:03:10.124677+03	2026-02-13 17:03:10.124677+03	\N	\N	2026-02-13 17:03:10.124677+03	\N	\N	manual	\N	\N	\N	\N
40	1	1	2026-02-14	1	1	9	1	\N	t	2026-02-14 14:36:04.090742+03	2026-02-14 14:37:05.993658+03	2026-02-14 14:37:05.993658+03	32	2026-02-14 14:36:04.090742+03	2026-02-14 14:37:05.993658+03	\N	manual	\N	\N	\N	\N
45	1	1	2026-02-24	1	1	9	1	\N	t	2026-02-24 22:03:28.294967+03	2026-02-24 22:04:05.101824+03	2026-02-24 22:04:05.101824+03	32	2026-02-24 22:03:28.294967+03	2026-02-24 22:04:05.101824+03	\N	manual	\N	\N	\N	\N
46	1	1	2026-02-24	2	1	9	1	\N	t	2026-02-24 22:25:49.223987+03	2026-02-24 22:26:09.786147+03	2026-02-24 22:26:09.786147+03	32	2026-02-24 22:25:49.223987+03	2026-02-24 22:26:09.786147+03	\N	manual	\N	\N	\N	\N
\.


--
-- Data for Name: continuing_batch_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.continuing_batch_items (id, batch_id, student_id, from_enrollment_id, to_grade_id, to_section_id, to_enrollment_id, decision, reason, created_at) FROM stdin;
\.


--
-- Data for Name: continuing_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.continuing_batches (id, from_year_id, to_year_id, mode, keep_section, default_section_id, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (id, user_id, teacher_id, full_name, phone, job_title, notes, is_teacher, is_active, created_at, updated_at, school_id) FROM stdin;
10	38	\N	مروان جمال	770000009	تسجيل وقبول	\N	f	t	2026-01-08 23:03:17.353916+03	2026-01-14 21:58:48.290753+03	1
8	41	\N	ناصر حسين	770000007	\N	\N	f	t	2026-01-08 23:03:17.353916+03	2026-01-14 21:58:48.720904+03	1
7	\N	7	حسن عمر	770000006	\N	\N	t	t	2026-01-08 23:03:17.353916+03	2026-01-14 21:58:55.05699+03	1
5	\N	5	ماهر أحمد	770000004	\N	\N	t	t	2026-01-08 23:03:17.353916+03	2026-01-14 21:58:55.485174+03	1
2	\N	2	أحمد محمد	770000001	\N	\N	t	t	2026-01-08 23:03:17.353916+03	2026-01-14 21:58:55.872847+03	1
1	32	1	الأستاذ أحمد محمد	777777777	\N	\N	t	t	2026-01-08 23:03:17.353916+03	2026-01-14 21:58:57.059109+03	1
12	46	12	امين عبده محمد غانم البعداني	770398951	teacher	\N	t	t	2026-01-24 15:03:28.196704+03	2026-01-24 15:03:28.196704+03	1
13	48	13	علي احمد قاسم النوري	575257386	admin@gmail.com	\N	t	t	2026-02-02 00:44:16.819676+03	2026-02-02 00:44:16.819676+03	1
\.


--
-- Data for Name: exam_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_entries (id, exam_schedule_id, exam_date, start_time, end_time, subject_id, room, supervisor_teacher_id, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: exam_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_schedules (id, academic_year_id, stage_id, grade_id, section_id, term, status, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: exam_timetable_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_timetable_entries (id, exam_timetable_id, exam_date, start_time, end_time, subject_id, room, notes, apply_to_section_id, created_at) FROM stdin;
3	1	2026-03-24	02:50:00	02:55:00	9	\N	\N	\N	2026-03-25 00:46:13.07404+03
10	5	2026-03-27	03:55:00	04:55:00	15	\N	\N	\N	2026-03-25 01:56:19.450765+03
11	5	2026-03-28	03:55:00	04:55:00	18	\N	\N	\N	2026-03-25 01:56:19.450765+03
12	5	2026-03-29	03:55:00	04:55:00	17	\N	\N	\N	2026-03-25 01:56:19.450765+03
51	9	2026-03-25	23:40:00	23:57:00	9	\N	\N	\N	2026-03-25 23:40:36.415984+03
52	9	2026-03-26	17:50:00	18:50:00	15	\N	\N	\N	2026-03-25 23:40:36.415984+03
\.


--
-- Data for Name: exam_timetables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_timetables (id, academic_year_id, stage_id, grade_id, scope, section_id, exam_type, month, status, created_by, created_at, updated_at) FROM stdin;
1	1	1	1	grade	\N	midyear	\N	published	1	2026-02-25 23:48:00.449811+03	2026-03-25 00:46:13.091652+03
5	3	1	1	section	1	midyear	\N	published	1	2026-03-25 01:54:43.820595+03	2026-03-25 01:56:19.467788+03
7	3	1	2	section	3	midyear	\N	draft	1	2026-03-25 02:04:22.526384+03	2026-03-25 02:04:22.526384+03
8	2	1	2	section	3	midyear	\N	draft	1	2026-03-25 02:04:28.847659+03	2026-03-25 02:04:28.847659+03
9	2	1	1	section	1	midyear	\N	published	1	2026-03-25 17:49:50.341812+03	2026-03-25 23:40:36.43005+03
\.


--
-- Data for Name: fee_contracts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fee_contracts (id, student_id, academic_year_id, annual_amount, installments_count, first_due_date, status, created_at, updated_at, discount_amount, discount_reason) FROM stdin;
2	24	2	120000	3	2026-03-05	active	2026-03-05 20:58:56.653712+03	2026-03-05 20:58:56.653712+03	0.00	\N
3	15	2	200000	10	2026-03-08	active	2026-03-08 00:26:51.00356+03	2026-03-08 00:26:51.00356+03	0.00	\N
4	21	2	200000	10	2026-03-09	active	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03	0.00	\N
6	26	2	100000	5	2026-03-11	active	2026-03-10 22:12:12.215276+03	2026-03-10 22:12:12.215276+03	0.00	\N
7	20	2	200000	20	2026-03-09	active	2026-03-10 23:01:38.412895+03	2026-03-10 23:01:38.412895+03	0.00	\N
8	27	2	200000	10	2026-03-09	active	2026-03-10 23:47:13.012856+03	2026-03-10 23:47:13.012856+03	50000.00	\N
\.


--
-- Data for Name: fee_installments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fee_installments (id, contract_id, installment_no, due_date, amount, paid_amount, status, created_at, updated_at) FROM stdin;
1	2	1	2026-03-05	40000	40000	paid	2026-03-05 20:59:21.726592+03	2026-03-08 00:23:58.928607+03
2	2	2	2026-04-04	40000	40000	paid	2026-03-05 20:59:21.726592+03	2026-03-08 00:23:58.928607+03
3	2	3	2026-05-04	40000	40000	paid	2026-03-05 20:59:21.726592+03	2026-03-08 00:23:58.928607+03
4	3	1	2026-03-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 00:27:09.936086+03
5	3	2	2026-04-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 00:40:39.821074+03
6	3	3	2026-05-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:26.315909+03
7	3	4	2026-06-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:26.858134+03
8	3	5	2026-07-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:27.401112+03
9	3	6	2026-08-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:27.401112+03
10	3	7	2026-09-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:27.401112+03
11	3	8	2026-10-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:27.401112+03
12	3	9	2026-11-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:27.401112+03
13	3	10	2026-12-08	20000	20000	paid	2026-03-08 00:26:51.00356+03	2026-03-08 01:33:27.401112+03
14	4	1	2026-03-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
15	4	2	2026-04-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
16	4	3	2026-05-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
17	4	4	2026-06-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
18	4	5	2026-07-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
19	4	6	2026-08-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
20	4	7	2026-09-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
21	4	8	2026-10-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
22	4	9	2026-11-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
23	4	10	2026-12-09	20000	0	unpaid	2026-03-09 23:06:55.415215+03	2026-03-09 23:06:55.415215+03
30	6	2	2026-04-11	20000	0	unpaid	2026-03-10 22:12:12.215276+03	2026-03-10 22:12:12.215276+03
31	6	3	2026-05-11	20000	0	unpaid	2026-03-10 22:12:12.215276+03	2026-03-10 22:12:12.215276+03
32	6	4	2026-06-11	20000	0	unpaid	2026-03-10 22:12:12.215276+03	2026-03-10 22:12:12.215276+03
33	6	5	2026-07-11	20000	0	unpaid	2026-03-10 22:12:12.215276+03	2026-03-10 22:12:12.215276+03
29	6	1	2026-03-11	20000	20000	paid	2026-03-10 22:12:12.215276+03	2026-03-10 22:16:09.950591+03
44	7	1	2026-03-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
45	7	2	2026-04-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
46	7	3	2026-05-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
47	7	4	2026-06-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
48	7	5	2026-07-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
49	7	6	2026-08-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
50	7	7	2026-09-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
51	7	8	2026-10-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
52	7	9	2026-11-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
53	7	10	2026-12-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
54	7	11	2027-01-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
55	7	12	2027-02-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
56	7	13	2027-03-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
57	7	14	2027-04-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
58	7	15	2027-05-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
59	7	16	2027-06-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
60	7	17	2027-07-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
61	7	18	2027-08-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
62	7	19	2027-09-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
63	7	20	2027-10-09	10000	0	unpaid	2026-03-10 23:01:45.959129+03	2026-03-10 23:01:45.959129+03
119	8	1	2026-03-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
120	8	2	2026-04-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
121	8	3	2026-05-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
122	8	4	2026-06-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
123	8	5	2026-07-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
124	8	6	2026-08-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
125	8	7	2026-09-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
126	8	8	2026-10-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
127	8	9	2026-11-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
128	8	10	2026-12-09	15000	0	unpaid	2026-03-11 00:18:21.632131+03	2026-03-11 00:18:21.632131+03
\.


--
-- Data for Name: fee_payment_allocations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fee_payment_allocations (id, payment_id, installment_id, allocated_amount, created_at) FROM stdin;
1	2	1	20000	2026-03-07 03:24:03.911298+03
2	3	1	20000	2026-03-08 00:23:58.928607+03
3	3	2	40000	2026-03-08 00:23:58.928607+03
4	3	3	40000	2026-03-08 00:23:58.928607+03
5	4	4	20000	2026-03-08 00:27:09.936086+03
6	5	5	20000	2026-03-08 00:40:39.821074+03
7	6	6	20000	2026-03-08 01:33:26.315909+03
8	7	7	20000	2026-03-08 01:33:26.858134+03
9	8	8	20000	2026-03-08 01:33:27.401112+03
10	8	9	20000	2026-03-08 01:33:27.401112+03
11	8	10	20000	2026-03-08 01:33:27.401112+03
12	8	11	20000	2026-03-08 01:33:27.401112+03
13	8	12	20000	2026-03-08 01:33:27.401112+03
14	8	13	20000	2026-03-08 01:33:27.401112+03
15	12	29	20000	2026-03-10 22:16:09.950591+03
\.


--
-- Data for Name: fee_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fee_payments (id, contract_id, student_id, amount, method, provider, reference, note, attachment_path, attachment_mime, status, receipt_number, paid_at, created_at) FROM stdin;
2	2	24	20000	cash	يدوي	5446	\N	\N	\N	confirmed	RC-20260307-3496	2026-03-07 03:24:03.911298+03	2026-03-07 03:24:03.911298+03
3	2	24	200000	cash	يدوي	56464645645	\N	uploads\\1772918638796_ae95429ffb64c.png	image/png	confirmed	RC-20260308-3372	2026-03-08 00:23:58.928607+03	2026-03-08 00:23:58.928607+03
4	3	15	20000	cash	يدوي	45643453456	\N	\N	\N	confirmed	RC-20260308-4266	2026-03-08 00:27:09.936086+03	2026-03-08 00:27:09.936086+03
5	3	15	20000	wallet	جيب	354354345	54345	uploads\\1772918957166_c76647b1f087d.png	image/png	confirmed	PR-RC-20260308-2732	2026-03-08 00:29:17.183278+03	2026-03-08 00:29:17.183278+03
6	3	15	20000	wallet	جيب	54646	46546	\N	\N	confirmed	PR-RC-20260308-1995	2026-03-08 01:19:46.586723+03	2026-03-08 01:19:46.586723+03
7	3	15	20000	wallet	جيب	787	فافلبرافغ	\N	\N	confirmed	PR-RC-20260308-4863	2026-03-08 01:26:59.512353+03	2026-03-08 01:26:59.512353+03
8	3	15	200000	wallet	جيب	545	فافلبرافغ	\N	\N	confirmed	PR-RC-20260308-7348	2026-03-08 01:29:12.666114+03	2026-03-08 01:29:12.666114+03
10	2	24	20000	wallet	جيب	\N	\N	uploads\\1772930424647_17a855f278699.png	image/png	confirmed	PR-RC-20260308-6550	2026-03-08 03:40:24.671715+03	2026-03-08 03:40:24.671715+03
1	2	24	20000	wallet	جيب	\N	فافلبرافغ	uploads\\1772733714217_5e34d74f6ad1b.png	image/png	confirmed	PR-RC-20260305-5560	2026-03-05 21:01:54.2474+03	2026-03-05 21:01:54.2474+03
11	2	24	200021	wallet	جيب	253254	فافلبرافغ	\N	\N	pending	PR-RC-20260308-9643	2026-03-08 03:49:13.44695+03	2026-03-08 03:49:13.44695+03
9	3	15	20000	transfer	جيب	242	فافلبرافغ	\N	\N	confirmed	PR-RC-20260308-3947	2026-03-08 01:42:35.442942+03	2026-03-08 01:42:35.442942+03
12	6	26	20000	wallet	جيب	65463543545	شكرا	uploads\\1773170120474_8a1974b3daf38.png	image/png	confirmed	PR-RC-20260310-8840	2026-03-10 22:15:20.50251+03	2026-03-10 22:15:20.50251+03
\.


--
-- Data for Name: fee_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fee_rules (id, academic_year_id, scope, stage_id, grade_id, section_id, student_id, annual_amount, installments_count, first_due_date, interval_months, reason_code, notes, is_active, created_at, updated_at) FROM stdin;
1	2	DEFAULT	\N	\N	\N	\N	120000	3	2026-03-05	1	default	\N	t	2026-03-05 22:23:26.31039+03	2026-03-05 22:23:26.31039+03
2	2	STAGE	1	\N	\N	\N	100000	5	2026-03-11	1	\N	\N	t	2026-03-05 22:49:42.93144+03	2026-03-05 22:49:42.93144+03
\.


--
-- Data for Name: grade_change_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grade_change_logs (id, grade_id, changed_by, old_status, new_status, old_score, new_score, reason, changed_at) FROM stdin;
1	1	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
2	2	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
3	3	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
4	4	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
5	5	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
6	6	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
7	7	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
8	8	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
9	9	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:19:23.480216+03
10	10	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
11	11	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
12	12	32	\N	graded	\N	10.00	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
13	13	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
14	14	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
15	15	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
16	16	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
17	17	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
18	18	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 00:28:47.168584+03
19	19	32	\N	graded	\N	1.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
20	20	32	\N	graded	\N	2.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
21	21	32	\N	graded	\N	3.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
22	22	32	\N	graded	\N	4.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
23	23	32	\N	graded	\N	5.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
24	24	32	\N	graded	\N	6.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
25	25	32	\N	graded	\N	7.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
26	26	32	\N	graded	\N	8.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
27	27	32	\N	graded	\N	9.00	إنشاء درجة جديدة	2026-03-25 17:41:50.898967+03
28	28	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
29	29	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
30	30	32	\N	graded	\N	10.00	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
31	31	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
32	32	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
33	33	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
34	34	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
35	35	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
36	36	32	\N	missing	\N	\N	إنشاء درجة جديدة	2026-03-25 18:09:44.223095+03
37	37	32	\N	graded	\N	1.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
38	38	32	\N	graded	\N	2.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
39	39	32	\N	graded	\N	3.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
40	40	32	\N	graded	\N	4.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
41	41	32	\N	graded	\N	5.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
42	42	32	\N	graded	\N	6.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
43	43	32	\N	graded	\N	7.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
44	44	32	\N	graded	\N	8.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
45	45	32	\N	graded	\N	9.00	إنشاء درجة جديدة	2026-03-27 00:22:22.240341+03
46	46	32	\N	graded	\N	1.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
47	47	32	\N	graded	\N	2.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
48	48	32	\N	graded	\N	3.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
49	49	32	\N	graded	\N	4.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
50	50	32	\N	graded	\N	5.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
51	51	32	\N	graded	\N	6.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
52	52	32	\N	graded	\N	7.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
53	53	32	\N	graded	\N	8.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
54	54	32	\N	graded	\N	9.00	إنشاء درجة جديدة	2026-03-27 18:00:09.776329+03
\.


--
-- Data for Name: grade_policies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grade_policies (id, academic_year_id, term, subject_id, stage_id, grade_id, weights_json, rounding_rule, created_at, midterm_aggregate_weight, midterm_exam_weight, final_aggregate_weight, final_exam_weight, max_total_score, passing_score, monthly_exam_count, is_active, notes) FROM stdin;
\.


--
-- Data for Name: grade_subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grade_subjects (id, grade_id, subject_id, is_active, created_at, updated_at, school_id) FROM stdin;
9	1	17	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
8	1	16	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
7	1	15	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
6	1	9	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
5	1	8	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
4	1	7	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
3	1	3	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
2	1	2	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
1	1	1	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
16	2	9	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
15	2	8	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
14	2	7	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
13	2	3	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
12	2	2	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
11	2	1	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
30	3	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
29	3	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
142	1	19	t	2026-01-13 22:58:31.713217+03	2026-01-13 22:58:31.713217+03	3
10	1	18	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:58:31.713217+03	3
131	2	19	t	2026-01-13 22:51:43.462122+03	2026-01-13 22:51:43.462122+03	3
20	2	18	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
19	2	17	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
18	2	16	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
17	2	15	t	2026-01-12 23:37:21.171794+03	2026-01-13 22:51:43.462122+03	3
28	3	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
27	3	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
26	3	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
25	3	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
24	3	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
23	3	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
22	3	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
21	3	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
40	4	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
39	4	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
38	4	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
37	4	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
36	4	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
35	4	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
34	4	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
33	4	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
32	4	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
31	4	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
50	5	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
49	5	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
48	5	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
47	5	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
46	5	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
45	5	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
44	5	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
43	5	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
42	5	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
41	5	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
60	6	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
59	6	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
58	6	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
57	6	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
56	6	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
55	6	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
54	6	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
53	6	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
52	6	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
51	6	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
90	9	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
89	9	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
88	9	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
87	9	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
86	9	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
85	9	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
84	9	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
83	9	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
82	9	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
81	9	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
70	7	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
69	7	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
68	7	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
67	7	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
66	7	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
65	7	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
64	7	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
63	7	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
62	7	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
61	7	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
80	8	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
79	8	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
78	8	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
77	8	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
76	8	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
75	8	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
74	8	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
73	8	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
72	8	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
71	8	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	3
91	10	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
92	10	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
93	10	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
94	10	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
95	10	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
96	10	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
97	10	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
98	10	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
99	10	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
100	10	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
101	11	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
102	11	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
103	11	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
104	11	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
105	11	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
106	11	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
107	11	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
108	11	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
109	11	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
110	11	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
111	12	1	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
112	12	2	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
113	12	3	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
114	12	7	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
115	12	8	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
116	12	9	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
117	12	15	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
118	12	16	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
119	12	17	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
120	12	18	t	2026-01-12 23:37:21.171794+03	2026-01-12 23:37:21.171794+03	1
\.


--
-- Data for Name: grades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grades (id, stage_id, name, order_no, is_active, created_at, updated_at, order_index, school_id) FROM stdin;
1	1	الاول	1	t	2026-03-01 01:43:52.651916+03	2026-03-01 01:43:52.651916+03	1	3
2	1	الثاني	2	t	2026-03-01 01:44:05.467034+03	2026-03-01 01:44:05.467034+03	2	3
3	1	الثالث	3	t	2026-03-01 01:44:15.928644+03	2026-03-01 01:44:15.928644+03	3	3
4	1	الرابع	4	t	2026-03-01 01:44:39.11214+03	2026-03-01 01:44:39.11214+03	4	3
5	1	الخامس	5	t	2026-03-01 01:44:49.161613+03	2026-03-01 01:44:49.161613+03	5	3
6	1	السادس	6	t	2026-03-01 01:44:59.485826+03	2026-03-01 01:44:59.485826+03	6	3
9	2	ثالث اعدادي	9	t	2026-03-01 01:45:45.241792+03	2026-03-01 01:45:45.241792+03	9	3
7	2	اول اعدادي	7	t	2026-03-01 01:45:15.400687+03	2026-03-01 01:45:56.271662+03	7	3
8	2	ثاني اعدادي	8	t	2026-03-01 01:45:25.37156+03	2026-03-01 01:46:16.690398+03	8	3
\.


--
-- Data for Name: guardians; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.guardians (id, user_id, full_name, gender, phone, email, address, created_at, updated_at, school_id) FROM stdin;
1	\N	نبيل الصوفي	male	777333444	nabil@example.com	تعز - الحي القديم	2025-12-12 04:11:33.429266+03	\N	1
6	23	امين البعداني	male	4564645654654	parent@gmail.com	ذي السفال	2025-12-19 01:09:59.384745+03	\N	1
7	25	امين البعدانيjb	male	456464565465454	parentt@gmail.com	ذي السفال	2025-12-19 15:18:07.64887+03	\N	1
2	\N	أم رانيا	female	777444555	mother.rania@example.com	تعز - المدينة	2025-12-12 04:11:33.429266+03	\N	1
5	21	امين البعداني	male	4564645654654	ameen@gmail.com	ameen@gmail.com	2025-12-19 01:01:18.947845+03	\N	1
12	27	احمد البعجاني	male	321	ahmeds@gmail.com	الجبوب	2025-12-24 23:30:16.477117+03	\N	1
14	50	امين عبده محمد غانم البعداني البعداني	male	770398951	ameenalbadani@gmail.com	ذي السفال	2026-02-21 21:19:37.845714+03	\N	1
13	33	وليد الجنيد	male	772611048	waleed@gmail.com	ذي السفال	2026-01-01 17:50:50.016063+03	\N	1
\.


--
-- Data for Name: lesson_substitutions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lesson_substitutions (id, substitution_date, timetable_entry_id, absent_teacher_id, substitute_teacher_id, assigned_by_user_id, created_at, status) FROM stdin;
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modules (id, name, code, description, created_at, updated_at) FROM stdin;
16	التسجيل والقبول	admission	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
17	الموظفين	staff	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
18	جداول المدرسة	timetable	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
19	الكنترول	control	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
20	الإشعارات	notify	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
21	الحضور والغياب	attendance	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
22	الرسوم الدراسية	fees	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
23	التقارير العامة	reports	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
24	إدارة المستخدمين والصلاحيات	rbac	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
25	إدارة الغيابات	absences	\N	2025-12-03 03:34:02.916084	2025-12-03 03:34:02.916084
26	التقويم والسنوات الدراسية	calendar	\N	2026-01-11 01:42:07.034367	2026-01-11 01:42:07.034367
27	الاعدادات	Settings	\N	2026-01-13 01:57:48.237053	2026-01-13 01:57:48.237053
\.


--
-- Data for Name: notification_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_attachments (id, notification_id, kind, original_name, mime_type, size_bytes, storage_path, link_url, link_label, created_at) FROM stdin;
\.


--
-- Data for Name: notification_recipients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_recipients (id, notification_id, recipient_user_id, is_read, read_at, created_at) FROM stdin;
1	1	1	t	2026-02-24 02:23:20.981781+03	2026-02-24 00:01:05.206025+03
3	2	18	f	\N	2026-02-24 22:24:02.711885+03
5	3	18	f	\N	2026-02-24 22:26:09.884188+03
6	4	46	f	\N	2026-02-24 23:47:25.500911+03
8	4	48	f	\N	2026-02-24 23:47:25.500911+03
2	2	1	t	2026-02-25 00:08:41.510015+03	2026-02-24 22:24:02.711885+03
4	3	1	t	2026-02-25 00:08:48.353918+03	2026-02-24 22:26:09.884188+03
11	6	18	f	\N	2026-02-25 22:47:18.629099+03
10	6	1	t	2026-02-25 22:50:33.852762+03	2026-02-25 22:47:18.629099+03
9	5	32	t	2026-02-26 00:11:43.513551+03	2026-02-25 00:59:49.168+03
7	4	32	t	2026-02-26 00:11:47.608871+03	2026-02-24 23:47:25.500911+03
14	8	49	f	\N	2026-02-26 01:02:35.835536+03
16	10	24	f	\N	2026-02-26 01:02:57.314626+03
17	10	22	f	\N	2026-02-26 01:02:57.314626+03
19	10	44	f	\N	2026-02-26 01:02:57.314626+03
20	10	49	f	\N	2026-02-26 01:02:57.314626+03
13	7	1	t	2026-02-26 01:08:38.376288+03	2026-02-26 01:01:02.261214+03
21	11	49	t	2026-02-26 01:52:48.889134+03	2026-02-26 01:29:48.37178+03
24	13	48	f	\N	2026-02-26 01:53:20.560109+03
26	14	18	f	\N	2026-02-26 02:04:34.523744+03
28	15	18	f	\N	2026-02-26 02:04:37.243603+03
30	16	18	f	\N	2026-02-26 02:04:37.960912+03
32	17	48	f	\N	2026-02-26 02:04:55.644829+03
34	18	18	f	\N	2026-02-26 02:07:08.810238+03
25	14	1	t	2026-02-26 03:52:56.457449+03	2026-02-26 02:04:34.523744+03
27	15	1	t	2026-02-26 03:52:56.457449+03	2026-02-26 02:04:37.243603+03
29	16	1	t	2026-02-26 03:52:56.457449+03	2026-02-26 02:04:37.960912+03
33	18	1	t	2026-02-26 03:52:56.457449+03	2026-02-26 02:07:08.810238+03
36	23	18	f	\N	2026-02-26 04:16:07.532122+03
39	25	18	f	\N	2026-02-26 04:16:49.834768+03
22	12	33	t	2026-02-26 04:19:09.915621+03	2026-02-26 01:29:55.619133+03
15	9	33	t	2026-02-26 04:56:43.846896+03	2026-02-26 01:02:51.690097+03
40	26	45	f	\N	2026-02-26 22:12:06.024803+03
41	27	45	f	\N	2026-02-26 22:12:11.746838+03
42	27	44	f	\N	2026-02-26 22:12:11.746838+03
44	27	49	f	\N	2026-02-26 22:12:11.746838+03
46	27	35	f	\N	2026-02-26 22:12:11.746838+03
47	27	36	f	\N	2026-02-26 22:12:11.746838+03
49	28	18	f	\N	2026-02-26 22:12:16.263998+03
52	30	48	f	\N	2026-02-26 22:51:15.430295+03
51	30	32	t	2026-02-26 22:51:36.428604+03	2026-02-26 22:51:15.430295+03
54	31	48	f	\N	2026-02-26 23:27:20.749705+03
57	34	32	t	2026-02-27 00:35:14.767003+03	2026-02-27 00:34:40.976277+03
35	23	1	t	2026-03-02 21:56:26.151374+03	2026-02-26 04:16:07.532122+03
38	25	1	t	2026-03-02 21:56:26.151374+03	2026-02-26 04:16:49.834768+03
48	28	1	t	2026-03-02 21:56:26.151374+03	2026-02-26 22:12:16.263998+03
43	27	34	t	2026-03-10 23:00:24.513771+03	2026-02-26 22:12:11.746838+03
37	24	34	t	2026-03-10 23:00:26.701091+03	2026-02-26 04:16:48.914401+03
23	13	32	t	2026-03-24 22:16:05.538978+03	2026-02-26 01:53:20.560109+03
31	17	32	t	2026-03-24 22:16:05.538978+03	2026-02-26 02:04:55.644829+03
50	29	32	t	2026-03-24 22:16:05.538978+03	2026-02-26 22:50:15.600869+03
53	31	32	t	2026-03-24 22:16:05.538978+03	2026-02-26 23:27:20.749705+03
55	32	32	t	2026-03-24 22:16:05.538978+03	2026-02-26 23:30:06.911244+03
56	33	32	t	2026-03-24 22:16:05.538978+03	2026-02-27 00:19:43.102888+03
58	35	32	t	2026-03-24 22:16:05.538978+03	2026-02-27 00:40:04.730989+03
59	36	32	t	2026-03-24 22:16:05.538978+03	2026-02-27 01:22:43.559456+03
18	10	43	t	2026-03-24 23:23:33.67256+03	2026-02-26 01:02:57.314626+03
45	27	43	t	2026-03-24 23:23:33.67256+03	2026-02-26 22:12:11.746838+03
60	37	1	t	2026-03-25 16:24:50.851065+03	2026-03-08 01:42:35.563148+03
61	38	1	t	2026-03-25 16:24:50.851065+03	2026-03-08 03:40:24.89988+03
62	39	1	t	2026-03-25 16:24:50.851065+03	2026-03-08 03:49:13.617632+03
63	40	1	t	2026-03-25 16:24:50.851065+03	2026-03-10 22:15:20.723014+03
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, source, category, priority, title, body, sender_user_id, sender_display_name, related_type, related_id, meta, created_at) FROM stdin;
1	system	attendance	urgent	اختبار صندوق الوارد (نظام)	هذا إشعار تجريبي من النظام لاختبار صفحة صندوق الوارد وربط الـ API بنجاح.	\N	النظام	attendance_entry	999001	{"related_label": "سجل حضور تجريبي رقم 999001"}	2026-02-24 00:01:05.206025+03
2	system	permits	important	طلب استئذان جديد للطالب مهند وليد الجنيد	تم إنشاء طلب ABSENCE جديد للطالب مهند وليد الجنيد.\nمقدم الطلب: وليد الجنيد\nتاريخ الطلب: Tue Feb 24 2026 00:00:00 GMT+0300 (التوقيت العربي الرسمي)	\N	النظام	permission_request	25	{"request_type": "ABSENCE", "related_label": "طلب استئذان رقم 25", "request_status": "PENDING"}	2026-02-24 22:24:02.711885+03
3	system	admin	important	تم إغلاق جلسة حضور	تم إغلاق جلسة الحضور بنجاح.\nالتاريخ: Tue Feb 24 2026 00:00:00 GMT+0300 (التوقيت العربي الرسمي)\nالفصل: أ\nالمادة: الاجتماعيات\nالحصة: 2\nالمعلم: الأستاذ أحمد محمد	\N	النظام	attendance_session	46	{"related_label": "جلسة حضور رقم 46"}	2026-02-24 22:26:09.884188+03
4	manual	general	normal	gdfgdf	fdg	1	عبدالله البعداني	\N	\N	{"ui_source": "admin_send_page", "audience_breakdown": {"mode": "roles", "admins": 0, "direct": 0, "students": 0, "teachers": 3, "guardians": 0, "total_unique": 3, "academic_year_id": null}}	2026-02-24 23:47:25.500911+03
5	manual	general	normal	سش	يسشي	1	عبدالله البعداني	\N	\N	{"ui_source": "admin_send_page_target_builder", "ui_version": 2, "targets_count": 1, "targeting_mode": "targets", "payload_version": 2, "audience_breakdown": {"mode": "targets", "admins": 0, "direct": 0, "students": 0, "teachers": 1, "guardians": 0, "total_unique": 1, "deduped_count": 0, "targets_count": 1, "academic_year_id": null, "academic_year_ids": [], "duplicates_removed": 0, "total_before_dedupe": 1}}	2026-02-25 00:59:49.168+03
6	system	admin	important	تم إغلاق جلسة حضور	تم إغلاق جلسة الحضور بنجاح.\nالتاريخ: Wed Feb 25 2026 00:00:00 GMT+0300 (التوقيت العربي الرسمي)\nالفصل: أ\nالمادة: الاجتماعيات\nالحصة: 1\nالمعلم: الأستاذ أحمد محمد	\N	النظام	attendance_session	47	{"related_label": "جلسة حضور رقم 47"}	2026-02-25 22:47:18.629099+03
7	manual	general	normal	انبهكم على الطالب علي لقد اكثر بالغياب	ليسليس	32	ali	\N	\N	{"ui_source": "teacher_send_admins"}	2026-02-26 01:01:02.256969+03
8	manual	general	normal	يشسي	يشسي	32	ali	\N	\N	{"mode": "selected", "term": 1, "ui_source": "teacher_send_students", "academic_year_id": 1}	2026-02-26 01:02:35.830352+03
9	manual	general	normal	يشسي	يشسي	32	ali	\N	\N	{"ui_source": "teacher_send_guardians"}	2026-02-26 01:02:51.689061+03
10	manual	general	normal	يشسي	يشسي	32	ali	\N	\N	{"mode": "section_all", "term": 1, "ui_source": "teacher_send_students", "section_id": 1, "academic_year_id": 1}	2026-02-26 01:02:57.31328+03
11	manual	general	normal	احبك	سوف اعطيك الدرحة النهائيىة	32	ali	\N	\N	{"mode": "selected", "term": 1, "ui_source": "teacher_send_students", "academic_year_id": 1}	2026-02-26 01:29:48.363549+03
12	manual	general	normal	احبك	سوف اعطيك الدرحة النهائيىة	32	ali	\N	\N	{"ui_source": "teacher_send_guardians"}	2026-02-26 01:29:55.617772+03
13	manual	general	normal	bcvb	bcfbcvbfdg	49	سعيد علي قاسم نور	\N	\N	{"to": "teachers", "mode": "selected", "ui_source": "student_portal"}	2026-02-26 01:53:20.556784+03
14	manual	general	normal	dsad	adsadsa	49	سعيد علي قاسم نور	\N	\N	{"to": "admins", "ui_source": "student_portal"}	2026-02-26 02:04:34.519893+03
15	manual	general	normal	dsad	adsadsa	49	سعيد علي قاسم نور	\N	\N	{"to": "admins", "ui_source": "student_portal"}	2026-02-26 02:04:37.24025+03
16	manual	general	normal	dsad	adsadsa	49	سعيد علي قاسم نور	\N	\N	{"to": "admins", "ui_source": "student_portal"}	2026-02-26 02:04:37.958064+03
17	manual	general	normal	dsad	adsadsa	49	سعيد علي قاسم نور	\N	\N	{"to": "teachers", "mode": "selected", "ui_source": "student_portal"}	2026-02-26 02:04:55.641859+03
18	manual	general	normal	معاكم الطالب عبدالله البعدايني	اريد ان تراجعوا الدرجات والاختبارات الخاصة بي لاني احس نفسي مظلوم	49	سعيد علي قاسم نور	\N	\N	{"to": "admins", "ui_source": "student_portal"}	2026-02-26 02:07:08.806137+03
30	manual	general	normal	ارجو من المعلم ان يعيد كتابة الدرحات	ارجو من المعلم ان يعيد كتابة الدرحات	33	وليد الجنيد	\N	\N	{}	2026-02-26 22:51:15.426889+03
29	manual	general	normal	saSas	sASasa	33	وليد الجنيد	\N	\N	{}	2026-02-26 22:50:15.597987+03
28	manual	general	normal	امجد	sASAs	33	وليد الجنيد	\N	\N	{}	2026-02-26 22:12:16.262857+03
27	manual	general	normal	امجد	sASAs	33	وليد الجنيد	\N	\N	{}	2026-02-26 22:12:11.744821+03
26	manual	general	normal	امجد	sASAs	33	وليد الجنيد	\N	\N	{}	2026-02-26 22:12:06.013174+03
25	manual	general	normal	علي	علي	33	وليد الجنيد	\N	\N	{}	2026-02-26 04:16:49.833607+03
24	manual	general	normal	علي	علي	33	وليد الجنيد	\N	\N	{}	2026-02-26 04:16:48.911467+03
23	manual	general	normal	adasasd	dasdsadasdsad	33	وليد الجنيد	\N	\N	{}	2026-02-26 04:16:07.529509+03
31	manual	general	normal	تنبية	للبيلبيل	33	وليد الجنيد	\N	\N	{}	2026-02-26 23:27:20.742933+03
32	manual	general	normal	يشي	شيشي	33	وليد الجنيد	\N	\N	{}	2026-02-26 23:30:06.908442+03
33	manual	general	normal	dsad	asdasd	33	وليد الجنيد	\N	\N	{}	2026-02-27 00:19:43.099547+03
34	manual	general	normal	تاكيد لاختبار	البايبليبلسييبلبيليبلبيل	33	وليد الجنيد	\N	\N	{}	2026-02-27 00:34:40.971247+03
35	manual	general	normal	شسيسشيسشي	ئيسي	33	وليد الجنيد	\N	\N	{}	2026-02-27 00:40:04.72861+03
36	manual	general	normal	تنبية	الخباز	33	وليد الجنيد	\N	\N	{}	2026-02-27 01:22:43.555907+03
37	system	finance	important	حوالة رسوم جديدة	خالد وليد محمد عبدالحمن الجنيد — مبلغ: 20,000 — طريقة: transfer — الجهة: جيب — المرجع: 242 — إيصال: PR-RC-20260308-3947 (قيد المراجعة)	33	وليد الجنيد	fee_payment	9	{"amount": 20000, "method": "transfer", "status": "pending", "provider": "جيب", "paymentId": "9", "receiptNo": "PR-RC-20260308-3947", "reference": "242", "studentId": 15, "contractId": "3"}	2026-03-08 01:42:35.556703+03
38	system	finance	important	حوالة رسوم جديدة	محمد علي احمد الفاتح — مبلغ: 20,000 — طريقة: wallet — الجهة: جيب — إيصال: PR-RC-20260308-6550 (قيد المراجعة)	33	وليد الجنيد	fee_payment	10	{"amount": 20000, "method": "wallet", "status": "pending", "provider": "جيب", "paymentId": "10", "receiptNo": "PR-RC-20260308-6550", "reference": null, "studentId": 24, "contractId": "2"}	2026-03-08 03:40:24.854145+03
39	system	finance	important	حوالة رسوم جديدة	محمد علي احمد الفاتح — مبلغ: 200,021 — طريقة: wallet — الجهة: جيب — المرجع: 253254 — إيصال: PR-RC-20260308-9643 (قيد المراجعة)	33	وليد الجنيد	fee_payment	11	{"amount": 200021, "method": "wallet", "status": "pending", "provider": "جيب", "paymentId": "11", "receiptNo": "PR-RC-20260308-9643", "reference": "253254", "studentId": 24, "contractId": "2"}	2026-03-08 03:49:13.603168+03
40	system	finance	important	حوالة رسوم جديدة	اسلام امين عبده محمد البعداني — مبلغ: 20,000 — طريقة: wallet — الجهة: جيب — المرجع: 65463543545 — إيصال: PR-RC-20260310-8840 (قيد المراجعة)	33	وليد الجنيد	fee_payment	12	{"amount": 20000, "method": "wallet", "status": "pending", "provider": "جيب", "paymentId": "12", "receiptNo": "PR-RC-20260310-8840", "reference": "65463543545", "studentId": 26, "contractId": "6"}	2026-03-10 22:15:20.698402+03
\.


--
-- Data for Name: periods; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.periods (id, name, start_time, end_time, sort_order, created_at, updated_at, is_active) FROM stdin;
2	2	08:00:00	09:00:00	2	2025-12-29 21:44:19.276457+03	2026-01-24 16:43:14.103878+03	t
3	3	09:00:00	10:00:00	3	2025-12-29 21:44:19.276457+03	2026-01-24 16:45:50.703632+03	t
8	4	10:00:00	11:00:00	4	2025-12-29 23:00:17.649955+03	2026-01-24 16:46:02.992999+03	t
9	5	11:00:00	12:00:00	5	2025-12-29 23:00:17.649955+03	2026-01-24 16:49:13.203187+03	t
10	6	12:00:00	13:00:00	6	2025-12-29 23:00:17.649955+03	2026-01-24 16:49:19.427325+03	t
11	7	13:00:00	14:00:00	7	2026-01-02 17:49:17.144233+03	2026-01-24 16:49:40.133916+03	t
20	8	02:00:00	15:00:00	8	2026-01-02 17:56:40.123064+03	2026-01-24 16:49:50.265038+03	t
21	9	15:00:00	16:00:00	9	2026-01-02 21:39:46.754427+03	2026-01-24 16:50:00.872599+03	t
34	10	16:00:00	17:00:00	10	2026-01-13 22:51:14.133315+03	2026-01-24 16:50:29.339826+03	t
35	11	17:00:00	19:00:00	11	2026-01-14 00:53:35.854683+03	2026-01-24 17:20:31.178824+03	t
1	1	00:06:00	00:29:00	1	2025-12-29 21:44:19.276457+03	2026-03-26 00:05:28.750262+03	t
\.


--
-- Data for Name: permission_request_recipients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permission_request_recipients (id, request_id, teacher_id, is_read, created_at) FROM stdin;
\.


--
-- Data for Name: permission_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permission_requests (id, student_id, parent_user_id, request_date, type, time_from, time_to, reason_text, attachment_url, status, decided_by_user_id, decided_at, decision_note, created_at, updated_at) FROM stdin;
6	18	33	2026-01-29	ABSENCE	\N	\N	\N	\N	APPROVED	1	2026-01-29 00:03:50.559104+03	تم القبول	2026-01-28 23:58:24.531555+03	2026-01-29 00:03:50.559104+03
7	15	33	2026-01-29	LATE	09:27:00	\N	كان والدة  مريض	\N	REJECTED	1	2026-01-29 00:30:42.692498+03	سوف نقرر فيما بعد	2026-01-29 00:27:29.929226+03	2026-01-29 00:30:42.692498+03
3	2	33	2026-01-28	ABSENCE	\N	\N	مريض	\N	PENDING	1	2026-01-29 01:11:37.27624+03	ارجاع	2026-01-28 23:00:39.579859+03	2026-01-29 01:11:37.27624+03
8	18	33	2026-01-28	ABSENCE	\N	\N	مريض	\N	REJECTED	1	2026-01-29 01:11:50.627328+03	نرفض	2026-01-29 01:05:36.895944+03	2026-01-29 01:11:50.627328+03
9	18	33	2026-01-31	LATE	21:25:00	\N	مريض	\N	REJECTED	1	2026-01-31 15:26:01.513385+03	ممنوع الغياب 	2026-01-31 15:25:38.226771+03	2026-01-31 15:26:01.513385+03
10	18	33	2026-02-01	ABSENCE	\N	\N	مريض	\N	APPROVED	1	2026-02-01 23:48:33.788076+03	تم	2026-02-01 23:45:31.675325+03	2026-02-01 23:48:33.788076+03
12	20	33	2026-02-02	ABSENCE	\N	\N	مريض	\N	REJECTED	1	2026-02-02 01:48:58.861947+03	رفض	2026-02-02 01:35:59.656684+03	2026-02-02 01:48:58.861947+03
11	21	33	2026-02-02	ABSENCE	\N	\N	مريض	\N	APPROVED	1	2026-02-02 17:13:57.617764+03	\N	2026-02-02 00:16:34.537132+03	2026-02-02 17:13:57.617764+03
14	20	33	2026-02-05	ABSENCE	\N	\N	lvdq	\N	APPROVED	1	2026-02-05 01:05:43.947064+03	\N	2026-02-05 01:05:04.537354+03	2026-02-05 01:05:43.947064+03
13	18	33	2026-02-02	ABSENCE	\N	\N	مريض	\N	APPROVED	1	2026-02-05 01:06:16.429571+03	\N	2026-02-02 17:45:45.444745+03	2026-02-05 01:06:16.429571+03
15	17	33	2026-02-05	ABSENCE	\N	\N	مريض	\N	REJECTED	1	2026-02-05 01:26:11.22555+03	\N	2026-02-05 01:12:27.241649+03	2026-02-05 01:26:11.22555+03
16	21	33	2026-02-05	ABSENCE	\N	\N	مريض	\N	APPROVED	1	2026-02-05 23:19:09.524854+03	لقد تم قبولة 	2026-02-05 22:47:59.095123+03	2026-02-05 23:19:09.524854+03
18	18	33	2026-02-07	ABSENCE	\N	\N	تاعب	\N	APPROVED	1	2026-02-07 16:11:31.779621+03	\N	2026-02-07 16:09:29.509681+03	2026-02-07 16:11:31.779621+03
17	20	33	2026-02-07	ABSENCE	\N	\N	مريض قوي 	\N	REJECTED	1	2026-02-07 16:13:35.647744+03	\N	2026-02-07 14:19:01.671996+03	2026-02-07 16:13:35.647744+03
19	21	33	2026-02-07	LATE	22:32:00	\N	تاريخ بسبب كان يلعب 	\N	REJECTED	1	2026-02-07 17:34:14.288109+03	ممنوع التاخير	2026-02-07 17:32:30.903223+03	2026-02-07 17:34:14.288109+03
20	23	50	2026-02-21	ABSENCE	\N	\N	مريض 	\N	REJECTED	1	2026-02-21 21:35:35.586297+03	\N	2026-02-21 21:29:22.02622+03	2026-02-21 21:35:35.586297+03
21	20	33	2026-02-24	ABSENCE	\N	\N	\N	\N	PENDING	\N	\N	\N	2026-02-24 21:58:32.152153+03	\N
22	15	33	2026-02-24	ABSENCE	\N	\N	\N	\N	PENDING	\N	\N	\N	2026-02-24 22:08:08.820294+03	\N
23	22	33	2026-02-24	ABSENCE	\N	\N	\N	\N	PENDING	\N	\N	\N	2026-02-24 22:14:49.879522+03	\N
24	18	33	2026-02-24	ABSENCE	\N	\N	\N	\N	PENDING	\N	\N	\N	2026-02-24 22:22:16.831704+03	\N
25	16	33	2026-02-24	ABSENCE	\N	\N	\N	\N	PENDING	\N	\N	\N	2026-02-24 22:24:02.641675+03	\N
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permissions (id, module_id, name, code, created_at) FROM stdin;
40	16	تسجيل طالب جديد	admission.create_student	2025-12-03 03:34:41.669356
41	16	تعديل بيانات طالب	admission.update_student	2025-12-03 03:34:41.669356
42	16	حذف طالب	admission.delete_student	2025-12-03 03:34:41.669356
43	16	تسجيل المستمرين	admission.renew_student	2025-12-03 03:34:41.669356
44	17	عرض الموظفين	staff.view_employees	2025-12-03 03:34:41.669356
45	17	تسجيل موظف جديد	staff.create_employee	2025-12-03 03:34:41.669356
46	17	تعديل بيانات موظف	staff.update_employee	2025-12-03 03:34:41.669356
47	17	حذف موظف	staff.delete_employee	2025-12-03 03:34:41.669356
48	17	تعيين المدرسين على الفصول	staff.assign_teacher	2025-12-03 03:34:41.669356
49	18	عرض جداول الحصص	timetable.view	2025-12-03 03:34:41.669356
50	18	إنشاء / تعديل جداول الحصص	timetable.manage	2025-12-03 03:34:41.669356
51	18	حذف جدول حصص	timetable.delete	2025-12-03 03:34:41.669356
52	19	تسجيل الأعمال الشهرية	control.monthly_work	2025-12-03 03:34:41.669356
55	19	إدخال الدرجات النهائية	control.final_grades	2025-12-03 03:34:41.669356
56	20	إنشاء إشعار جديد	notify.create	2025-12-03 03:34:41.669356
57	20	حذف إشعار	notify.delete	2025-12-03 03:34:41.669356
58	20	عرض سجل الإشعارات	notify.view_log	2025-12-03 03:34:41.669356
59	21	تسجيل الحضور بالباركود	attendance.barcode	2025-12-03 03:34:41.669356
60	21	تسجيل الحضور يدويًا	attendance.manual	2025-12-03 03:34:41.669356
61	21	عرض تقارير الحضور	attendance.reports	2025-12-03 03:34:41.669356
62	22	سداد الرسوم	fees.pay	2025-12-03 03:34:41.669356
63	22	عرض تقارير الرسوم	fees.reports	2025-12-03 03:34:41.669356
64	22	إدارة أنواع الرسوم	fees.manage_types	2025-12-03 03:34:41.669356
65	23	تقارير بيانات الطلاب	reports.student_data	2025-12-03 03:34:41.669356
66	23	تقارير بيانات الموظفين	reports.staff_data	2025-12-03 03:34:41.669356
67	23	تقارير الدرجات الفصلية	reports.term_grades	2025-12-03 03:34:41.669356
68	23	تقارير الدرجات النهائية	reports.final_grades	2025-12-03 03:34:41.669356
69	23	إحصائيات الطلاب	reports.student_stats	2025-12-03 03:34:41.669356
70	24	إدارة الوحدات (Modules)	rbac.manage_modules	2025-12-03 03:34:41.669356
71	24	إدارة الصلاحيات	rbac.manage_permissions	2025-12-03 03:34:41.669356
72	24	إدارة الأدوار	rbac.manage_roles	2025-12-03 03:34:41.669356
73	24	إدارة المستخدمين	rbac.manage_users	2025-12-03 03:34:41.669356
74	25	عرض الغيابات	absences.view	2025-12-03 03:34:41.669356
39	16	عرض الطلاب	admission.view_students	2025-12-03 03:34:41.669356
53	19	تسجيل الأعمال الفصلية	control.term_work	2025-12-03 03:34:41.669356
54	19	طباعة الشهادات	control.print_certificates	2025-12-03 03:34:41.669356
75	20	صندوق الوارد	notify.inbox	2026-01-03 21:38:07.949744
77	26	عرض السنوات الدراسية	view_academic_years	2026-01-11 01:42:15.832245
78	26	عرض السنوات الدراسية (التقويم)	calendar.view_years	2026-01-11 01:42:15.832245
79	27	اعدادات المدرسة	Settings.School-Settings	2026-01-13 01:58:57.442818
80	22	اعدادات الرسوم	Graphics-settings	2026-03-05 21:37:58.295018
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_permissions (id, role_id, permission_id) FROM stdin;
1004	26	39
1005	26	40
1006	26	41
1007	27	49
1008	27	57
1009	27	60
1010	27	67
1011	27	68
1012	27	71
1013	27	75
1222	29	78
1223	29	40
1016	26	78
1017	26	77
1224	29	41
1225	29	42
1226	29	43
1227	29	44
1228	29	45
1229	29	46
1230	29	47
1231	29	48
1232	29	49
1233	29	50
1234	29	51
1235	29	52
1236	29	55
1237	29	56
1238	29	57
1239	29	58
1240	29	59
1241	29	60
1242	29	61
1243	29	62
1244	29	63
1245	29	64
1246	29	65
1247	29	66
1248	29	67
1249	29	68
1250	29	69
1251	29	70
1252	29	71
1253	29	72
1254	29	73
1255	29	74
1256	29	39
1257	29	53
1258	29	54
1259	29	75
1260	29	77
1262	29	79
1181	1	39
1182	1	40
1183	1	41
1184	1	42
1185	1	43
1186	1	44
1187	1	45
1188	1	46
1189	1	47
1190	1	48
1191	1	49
1192	1	50
1193	1	51
1194	1	52
1195	1	53
1196	1	54
1197	1	55
1198	1	56
1199	1	57
1200	1	58
1201	1	59
1202	1	60
1203	1	61
1204	1	62
1205	1	63
1206	1	64
1207	1	65
1208	1	66
1209	1	67
1210	1	68
1057	28	39
1058	28	40
1059	28	77
1060	28	78
1211	1	69
1212	1	70
1213	1	71
1214	1	72
1215	1	73
1216	1	74
1217	1	75
1218	1	77
1219	1	78
1220	1	79
1221	1	80
1263	29	80
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, description) FROM stdin;
1	admin	\N
2	teacher	\N
3	student	\N
4	parent	\N
26	التسجيل والقبول	
27	controll	
28	adminstrator	
29	school_admin	Main administrator for a school
\.


--
-- Data for Name: scan_token_uses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scan_token_uses (jti, used_at, teacher_id, session_id, student_id) FROM stdin;
\.


--
-- Data for Name: school_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.school_settings (id, school_id, default_language, grading_scale, pass_mark, attendance_policy, invoice_prefix, student_code_prefix, academic_year_starts_on, week_start_day, max_students, max_teachers, allow_parent_portal, allow_teacher_portal, created_at, updated_at) FROM stdin;
1	1	ar	100	50.00	daily	INV	STD	\N	6	\N	\N	t	t	2026-03-28 23:37:35.64595+03	2026-03-28 23:37:35.64595+03
2	3	ar	100	50.00	daily	INV	STD	\N	6	\N	\N	t	t	2026-03-29 00:44:14.304586+03	2026-03-29 00:44:14.304586+03
\.


--
-- Data for Name: schools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schools (id, name_ar, name_en, slug, code, logo_url, phone, alt_phone, email, website, country, city, address, timezone, currency_code, principal_name, established_date, license_number, subscription_status, is_active, created_at, updated_at) FROM stdin;
1	مدرسة البعداني	Al-Baadani School	al-baadani-school	SCH-001	\N	777777777	\N	info@al-baadani.com	\N	\N	\N	Yemen - Sanaa	Asia/Aden	YER	\N	\N	\N	trial	t	2026-03-28 23:37:08.965198+03	2026-03-28 23:37:08.965198+03
2	مدارس المعرفة	Al-Maarefa Schools	al-maarefa	MAR-001	\N	777222333	\N	info@almaarefa.com	\N	\N	\N	Yemen - Sanaa	Asia/Aden	YER	\N	\N	\N	trial	t	2026-03-29 00:41:57.349601+03	2026-03-29 00:41:57.349601+03
3	مدارس النور	Al-Noor Schools	al-noor	NOR-001	\N	777444555	\N	info@alnoor.com	\N	\N	\N	Yemen - Sanaa	Asia/Aden	YER	\N	\N	\N	trial	t	2026-03-29 00:44:14.304586+03	2026-03-29 00:44:14.304586+03
\.


--
-- Data for Name: schools_master_registry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schools_master_registry (id, admin_email, db_name, school_name_ar, school_name_en, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: section_advisors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.section_advisors (id, academic_year_id, term, section_id, teacher_id, role, is_active, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: section_subject_teachers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.section_subject_teachers (id, academic_year_id, term, section_id, subject_id, teacher_id, status, created_by, created_at, updated_at, school_id) FROM stdin;
169	3	1	1	1	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
168	3	1	1	8	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
167	3	1	1	16	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
166	3	1	1	7	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
165	3	1	1	3	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
164	3	1	1	2	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
163	3	1	1	17	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
162	3	1	1	18	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
161	3	1	1	15	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
160	3	1	1	9	1	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
53	2	1	1	19	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
52	2	1	1	1	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
51	2	1	1	8	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
50	2	1	1	16	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
49	2	1	1	7	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
48	2	1	1	3	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
47	2	1	1	2	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
46	2	1	1	17	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
45	2	1	1	18	2	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
44	2	1	1	15	1	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
43	2	1	1	9	1	active	1	2026-01-17 16:29:43.913893+03	2026-03-02 23:38:28.499595+03	3
170	3	1	1	19	2	active	1	2026-03-02 23:36:40.801571+03	2026-03-02 23:36:40.801571+03	3
75	1	1	1	19	2	active	1	2026-01-17 22:39:07.808869+03	2026-02-02 01:25:16.293629+03	3
1	1	1	1	1	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
5	1	1	1	8	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
8	1	1	1	16	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
4	1	1	1	7	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
3	1	1	1	3	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
2	1	1	1	2	13	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
9	1	1	1	17	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
10	1	1	1	18	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
7	1	1	1	15	2	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
6	1	1	1	9	1	active	\N	2026-01-12 23:40:48.601839+03	2026-02-02 01:25:16.293629+03	3
31	4	1	1	19	2	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
30	4	1	1	1	8	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
29	4	1	1	8	6	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
28	4	1	1	16	2	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
27	4	1	1	7	7	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
26	4	1	1	3	7	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
25	4	1	1	2	4	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
24	4	1	1	17	11	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
23	4	1	1	18	10	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
22	4	1	1	15	6	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
21	4	1	1	9	9	active	1	2026-01-14 22:25:57.956548+03	2026-01-15 00:47:40.439718+03	3
139	1	1	4	1	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
138	1	1	4	8	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
137	1	1	4	16	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
136	1	1	4	7	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
135	1	1	4	3	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
134	1	1	4	2	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
133	1	1	4	17	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
132	1	1	4	18	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
131	1	1	4	15	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
130	1	1	4	9	1	active	1	2026-02-05 01:09:30.664158+03	2026-02-05 01:09:30.664158+03	3
97	1	1	23	19	2	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
96	1	1	23	1	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
95	1	1	23	8	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
94	1	1	23	16	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
93	1	1	23	7	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
92	1	1	23	3	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
91	1	1	23	2	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
90	1	1	23	17	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
89	1	1	23	18	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
88	1	1	23	15	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
87	1	1	23	9	1	active	1	2026-01-19 16:16:24.155248+03	2026-01-19 16:16:24.155248+03	3
149	1	1	25	1	11	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
148	1	1	25	8	4	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
147	1	1	25	16	9	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
146	1	1	25	7	7	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
145	1	1	25	3	3	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
144	1	1	25	2	13	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
143	1	1	25	17	6	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
142	1	1	25	18	8	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
141	1	1	25	15	12	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
140	1	1	25	9	2	active	1	2026-02-21 21:22:16.797084+03	2026-02-21 21:22:16.797084+03	3
159	1	1	28	1	6	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
158	1	1	28	8	8	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
157	1	1	28	16	10	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
156	1	1	28	7	4	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
155	1	1	28	3	3	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
154	1	1	28	2	3	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
153	1	1	28	17	7	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
152	1	1	28	18	7	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
151	1	1	28	15	12	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
150	1	1	28	9	1	active	1	2026-02-21 21:24:00.649946+03	2026-02-21 21:24:00.649946+03	3
107	1	1	31	1	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
106	1	1	31	8	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
105	1	1	31	16	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
104	1	1	31	7	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
103	1	1	31	3	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
102	1	1	31	2	12	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
101	1	1	31	17	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
100	1	1	31	18	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
99	1	1	31	15	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
98	1	1	31	9	1	active	1	2026-01-24 15:06:11.086742+03	2026-01-24 15:06:11.086742+03	3
\.


--
-- Data for Name: sections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sections (id, grade_id, name, capacity, is_active, created_at, updated_at, school_id) FROM stdin;
1	1	أ	30	t	2025-12-16 18:50:09.850214+03	\N	3
2	1	ب	30	t	2025-12-16 18:50:09.850214+03	\N	3
3	2	أ	30	t	2025-12-16 18:50:09.850214+03	\N	3
4	7	أ	\N	t	2025-12-23 23:55:15.749221+03	\N	3
5	7	ب	\N	t	2025-12-23 23:55:15.749221+03	\N	3
6	7	ج	\N	t	2025-12-23 23:55:15.749221+03	\N	3
7	8	أ	\N	t	2025-12-23 23:55:15.749221+03	\N	3
8	8	ب	\N	t	2025-12-23 23:55:15.749221+03	\N	3
9	8	ج	\N	t	2025-12-23 23:55:15.749221+03	\N	3
10	9	أ	\N	t	2025-12-23 23:55:15.749221+03	\N	3
11	9	ب	\N	t	2025-12-23 23:55:15.749221+03	\N	3
12	9	ج	\N	t	2025-12-23 23:55:15.749221+03	\N	3
22	1	ج	\N	t	2025-12-23 23:56:21.980123+03	\N	3
23	2	ب	\N	t	2025-12-23 23:56:21.980123+03	\N	3
24	2	ج	\N	t	2025-12-23 23:56:21.980123+03	\N	3
25	3	أ	\N	t	2025-12-23 23:56:21.980123+03	\N	3
26	3	ب	\N	t	2025-12-23 23:56:21.980123+03	\N	3
27	3	ج	\N	t	2025-12-23 23:56:21.980123+03	\N	3
28	4	أ	\N	t	2025-12-23 23:56:21.980123+03	\N	3
29	4	ب	\N	t	2025-12-23 23:56:21.980123+03	\N	3
30	4	ج	\N	t	2025-12-23 23:56:21.980123+03	\N	3
31	5	أ	\N	t	2025-12-23 23:56:21.980123+03	\N	3
32	5	ب	\N	t	2025-12-23 23:56:21.980123+03	\N	3
33	5	ج	\N	t	2025-12-23 23:56:21.980123+03	\N	3
34	6	أ	\N	t	2025-12-23 23:56:21.980123+03	\N	3
35	6	ب	\N	t	2025-12-23 23:56:21.980123+03	\N	3
36	6	ج	\N	t	2025-12-23 23:56:21.980123+03	\N	3
13	10	أ	\N	t	2025-12-23 23:55:41.753552+03	\N	3
14	10	ب	\N	t	2025-12-23 23:55:41.753552+03	\N	3
15	10	ج	\N	t	2025-12-23 23:55:41.753552+03	\N	3
16	11	أ	\N	t	2025-12-23 23:55:41.753552+03	\N	3
17	11	ب	\N	t	2025-12-23 23:55:41.753552+03	\N	3
18	11	ج	\N	t	2025-12-23 23:55:41.753552+03	\N	3
19	12	أ	\N	t	2025-12-23 23:55:41.753552+03	\N	3
20	12	ب	\N	t	2025-12-23 23:55:41.753552+03	\N	3
37	12	ج	\N	t	2026-01-13 22:35:27.348818+03	2026-01-13 22:35:27.348818+03	3
\.


--
-- Data for Name: stages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stages (id, name, order_no, is_active, order_index, created_at, updated_at, school_id) FROM stdin;
4	الجامعة	4	t	4	2026-01-13 22:34:10.759131+03	2026-01-13 22:34:10.759131+03	3
1	الابتدائية	1	t	1	2025-12-16 18:48:14.449355+03	2026-01-14 00:31:41.156003+03	3
2	الإعدادية	2	t	2	2025-12-16 18:48:14.449355+03	2026-01-14 00:31:41.156003+03	3
3	الثانوية	3	t	3	2025-12-16 18:48:14.449355+03	2026-01-14 00:31:41.156003+03	3
\.


--
-- Data for Name: student_enrollments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_enrollments (id, student_id, academic_year_id, stage_id, grade_id, section_id, roll_number, status, created_at, term, school_id) FROM stdin;
16	7	2	1	3	1	\N	enrolled	2025-12-28 16:47:32.69755+03	1	1
8	7	1	1	1	1	\N	enrolled	2025-12-19 01:09:59.384745+03	1	1
45	22	2	1	1	1	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
25	22	1	1	1	1	5	enrolled	2026-02-11 23:29:27.733931+03	1	1
17	2	2	2	7	\N	\N	enrolled	2025-12-28 16:49:35.253287+03	1	1
3	2	1	2	7	\N	2	enrolled	2025-12-12 04:15:19.180785+03	1	1
34	6	2	1	1	1	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
7	6	1	1	1	1	\N	enrolled	2025-12-19 01:01:18.947845+03	1	1
35	13	2	3	11	18	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
14	13	1	3	11	18	\N	enrolled	2025-12-24 23:30:16.477117+03	1	1
36	14	2	1	5	32	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
15	14	1	1	5	32	\N	enrolled	2025-12-25 17:16:24.282994+03	1	1
46	23	2	1	4	28	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
26	23	1	1	4	28	\N	enrolled	2026-02-21 21:19:37.845714+03	1	1
39	16	2	3	10	14	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
19	16	1	3	10	14	\N	enrolled	2026-01-03 00:56:47.189827+03	1	1
40	17	2	2	7	4	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
20	17	1	2	7	4	\N	enrolled	2026-01-03 02:14:20.677612+03	1	1
42	18	2	1	1	1	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
21	18	1	1	1	1	\N	enrolled	2026-01-17 22:37:44.050039+03	1	1
43	20	2	1	1	1	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
23	20	1	1	1	1	\N	enrolled	2026-01-19 16:14:27.196664+03	1	1
44	21	2	1	2	23	\N	enrolled	2026-03-10 22:59:50.116235+03	1	1
24	21	1	1	2	23	\N	enrolled	2026-01-19 16:28:08.508173+03	1	1
27	24	2	1	1	1	\N	enrolled	2026-03-04 00:29:32.668869+03	1	1
29	26	2	1	1	1	\N	enrolled	2026-03-10 22:12:12.215276+03	1	1
49	27	2	1	1	1	\N	enrolled	2026-03-10 23:47:13.012856+03	1	1
18	15	2	1	1	1	\N	enrolled	2026-01-01 17:50:50.016063+03	1	1
\.


--
-- Data for Name: student_guardians; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_guardians (id, student_id, guardian_id, relation, is_primary, school_id) FROM stdin;
2	2	2	أم	t	1
5	6	5	والد	t	1
6	7	6	والد	t	1
12	13	12	اخ	t	1
13	14	12	\N	t	1
14	15	13	والد	t	1
15	16	13	\N	t	1
16	17	13	\N	t	1
17	18	13	\N	t	1
19	20	13	\N	t	1
20	21	13	\N	t	1
21	22	13	\N	t	1
22	23	14	والد	t	1
23	24	13	\N	t	1
25	26	13	\N	t	1
26	27	13	\N	t	1
\.


--
-- Data for Name: student_year_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_year_results (id, student_id, academic_year_id, result, reason, updated_by, updated_at, decided_at, decided_by) FROM stdin;
3	6	1	pending	\N	\N	2025-12-28 14:03:43.960435+03	\N	\N
4	13	1	pending	\N	\N	2025-12-28 14:03:43.960435+03	\N	\N
5	14	1	pending	\N	\N	2025-12-28 14:03:43.960435+03	\N	\N
1	7	1	passed	\N	\N	2025-12-28 14:03:43.960435+03	2025-12-28 14:17:04.836196+03	\N
2	2	1	failed	راسب	\N	2025-12-28 14:03:43.960435+03	2025-12-28 14:17:04.836196+03	\N
21	7	2	pending	\N	\N	2025-12-28 16:47:32.69755+03	\N	\N
22	2	2	pending	\N	\N	2025-12-28 16:49:35.253287+03	\N	\N
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.students (id, user_id, student_code, full_name, gender, birth_date, birth_place, address, phone, phone2, admission_date, status, created_at, updated_at, school_id) FROM stdin;
7	24	St-5225f-fk	عبدالله امين عبده محمد البعداني	male	2025-12-29	\N	ذي السفال	7725424554	5464654654645	2025-12-03	graduated	2025-12-19 01:09:59.384745+03	\N	1
22	49	St-5225-fksxsxdsad545	سعيد علي قاسم نور	male	2015-05-05	اب	ذي السفال	7725424554454	5464654654645323545	2026-02-11	active	2026-02-11 23:29:27.733931+03	\N	1
2	\N	ST-2025-002	رانيا نبيل - تعديل هاني	female	2013-11-21	تعز	تعز - الحوبان	777222333	\N	2025-09-01	active	2025-12-12 04:11:20.261166+03	2025-12-23 23:40:12.993768+03	1
6	22	St-5225-fk	عبدالله امين عبده محمد غانم البعداني	male	2025-12-15	اب	ذي السفال	7725424554	5464654654645	2025-12-02	active	2025-12-19 01:01:18.947845+03	2025-12-24 02:37:17.005637+03	1
13	28	St-5225-fksdf	عبدالله البعداني	male	2025-12-07	صنعاء	ذي السفال	123	123	2025-12-17	active	2025-12-24 23:30:16.477117+03	\N	1
14	29	St-5225-fksxsx	خالد وليد الجنيد	male	2025-12-22	صنعاء	ذي السفال	7725424554776732	546465465464512323	2025-12-03	active	2025-12-25 17:16:24.282994+03	2025-12-25 17:19:47.949165+03	1
23	51	St-5225-fkghj4	عبدالرحمن امين عبدة محمد غانم البعداني	male	2026-02-23	اب	ذي السفال	77254245544545	5464654654645323545	2026-02-11	active	2026-02-21 21:19:37.845714+03	\N	1
16	35	St-5225-fksxsxdsad	مهند وليد الجنيد	male	2026-01-13	اب	ذي السفال	22323213213	5464654654645323	2026-01-22	active	2026-01-03 00:56:47.189827+03	\N	1
17	36	St-5225-fksxsxsds	هلا وليد الجنيد	male	2005-10-18	اب	ذي السفال	7725424554213	54646546546453123	2026-02-12	active	2026-01-03 02:14:20.677612+03	\N	1
18	43	St-5225-fksdffg	عبدالله امين عبده محمد غانم البعداني	male	2026-01-05	اب	ذي السفال	77254245544432	54646546546454324	2026-01-29	active	2026-01-17 22:37:44.050039+03	\N	1
20	44	St-5225-fksxsdasxdsad	اين عليقاسم الجابري	male	2026-01-12	اب	ذي السفال	772542455443543	54646546546455435	2026-02-07	active	2026-01-19 16:14:27.196664+03	\N	1
21	45	St-5225-fkfdgfs	امجد علي احمد الكامل	male	2026-01-02	اب	ذي السفال	772542455423	5464654654645323	2026-02-06	active	2026-01-19 16:28:08.508173+03	\N	1
24	52	St-4545225-fksdf	محمد علي احمد الفاتح	male	2026-03-10	اب	ذي السفال	772542455445656	5464654654645456	2026-03-18	active	2026-03-04 00:29:32.668869+03	\N	1
26	53	St-5225-fkfdgfdsd	اسلام امين عبده محمد البعداني	male	2026-03-20	اب	ذي السفال	1236546456	64564564564565	2026-03-26	active	2026-03-10 22:12:12.215276+03	\N	1
27	54	St-5225-fksdffd	يوسف امين البعداني	male	2026-03-10	اب	ذي السفال	7725424554776732434	123423432423	2026-03-10	active	2026-03-10 23:47:13.012856+03	\N	1
15	34	St-5225-fksxsxds	خالد وليد محمد عبدالحمن الجنيد	male	2010-10-07	اب	ذي السفال	7725424554211	5464654654645212	2026-01-13	graduated	2026-01-01 17:50:50.016063+03	2026-03-24 23:59:35.455496+03	1
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subjects (id, name, is_active, created_at, updated_at, school_id) FROM stdin;
1	اللغة العربية	t	2025-12-29 21:44:31.215346+03	2025-12-29 21:44:31.215346+03	1
2	الرياضيات	t	2025-12-29 21:44:31.215346+03	2025-12-29 21:44:31.215346+03	1
3	العلوم	t	2025-12-29 21:44:31.215346+03	2025-12-29 21:44:31.215346+03	1
7	القرآن	t	2025-12-31 23:16:51.638705+03	2025-12-31 23:16:51.638705+03	1
8	اللغة الإنجليزية	t	2025-12-31 23:16:51.638705+03	2025-12-31 23:16:51.638705+03	1
15	التربية الإسلامية	t	2026-01-01 00:45:31.349165+03	2026-01-01 00:45:31.349165+03	1
16	القرآن الكريم	t	2026-01-01 00:45:31.349165+03	2026-01-01 00:45:31.349165+03	1
17	الرياضة	t	2026-01-01 00:45:31.349165+03	2026-01-01 00:45:31.349165+03	1
18	التربية الفنية	t	2026-01-01 00:45:31.349165+03	2026-01-01 00:45:31.349165+03	1
19	صراع اسرائيلي	t	2026-01-13 22:35:42.697891+03	2026-01-13 22:35:42.697891+03	1
9	الاجتماعيات	t	2025-12-31 23:16:51.638705+03	2026-01-14 01:01:56.473153+03	1
\.


--
-- Data for Name: submission_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.submission_attachments (id, submission_id, file_url, file_name, file_type, file_size, created_at) FROM stdin;
1	3	/uploads/submissions/sub_1774450670005_488260657.png	ââÙÙØ·Ø© Ø§ÙØ´Ø§Ø´Ø© (103).png	image/png	234969	2026-03-25 17:57:50.087932+03
\.


--
-- Data for Name: submissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.submissions (id, assessment_id, student_id, status, note, submitted_at, created_at, updated_at) FROM stdin;
1	6	15	submitted	هي كل ماذكر سؤال ممتاز وفي محله تماماً يا مهندس! لكي ننام قريري العين ونحن واثقون 100% أن هذه الشاشة هي "الريموت كنترول" الفعلي للنظام بالكامل، يجب أن نفحص "العقل المدبر" خلف زر (تفعيل) الذي يظهر في صورتك.\r\n\r\nبما أنك المطور، يمكنك التأكد من ذلك عبر خطوتين (واحدة برمجية، وواحدة عملية من الشاشة):	2026-03-25 00:05:39.088353+03	2026-03-25 00:05:39.088353+03	2026-03-25 00:05:39.088353+03
2	7	15	submitted	نعم شكرا على الاختبار اريد الدرجه النخائية	2026-03-25 00:27:31.213634+03	2026-03-25 00:27:31.213634+03	2026-03-25 00:27:31.213634+03
3	11	15	submitted	نعم لقد اجبتها كاملة	2026-03-25 17:57:50.087932+03	2026-03-25 17:57:50.087932+03	2026-03-25 17:57:50.087932+03
4	13	26	submitted	قصة بقرة بني إسرائيل (سبب التسمية): نزلت لتوضيح قصة قتيل بني إسرائيل، حيث أمر الله موسى عليه السلام بأن يأمر قومه بذبح بقرة وضرب الميت بجزء منها ليتكلم ويكشف قاتله.\r\nعلاج مشكلات المجتمع المدني: نزلت الآيات الأولى لتبيين أصناف المجتمع (مؤمنين، كافرين، منافقين)، ورسم معالم الدولة الإسلامية.\r\nآيات القتال (آية 217): نزلت في شأن سرية عبد الله بن جحش والشهر الحرام، قوله تعالى: ﴿يَسْأَلُونَكَ عَنِ الشَّهْرِ الْحَرَامِ قِتَالٍ فِيهِ﴾.\r\nالطعن في قصة الآيات (آية 26): نزل قوله تعالى: ﴿إِنَّ اللَّهَ لا يَسْتَحْيِي أَنْ يَضْرِبَ مَثَلاً مَا بَعُوضَةً فَمَا فَوْقَهَا﴾ ردًا على المنافقين الذين استنكروا ضرب الأمثال بالبعوض.\r\nالاستخلاف وقصة طالوت وجالوت: نزلت كقصة استكمال لقصة استخلاف آدم عليه السلام لبيان مفهوم الخلافة في الأرض.\r\nقصة صهيب الرومي (آية 207): نزلت في شأن صهيب الرومي الذي باع ماله للمشركين ليخرج إلى المدينة، قوله تعالى: ﴿وَمِنَ النَّاسِ مَنْ يَشْرِي نَفْسَهُ ابْتِغَاءَ مَرْضَاةِ اللَّهِ﴾.\r\nالطواف بين الصفا والمروة (آية 158): نزلت لطمأنة المسلمين الذين كرهوا الطواف بينهما ظنًا منهم أنه من أعمال الجاهلية.	2026-03-27 00:33:05.107988+03	2026-03-27 00:33:05.107988+03	2026-03-27 00:33:05.107988+03
5	13	15	submitted	قصة بقرة بني إسرائيل (سبب التسمية): نزلت لتوضيح قصة قتيل بني إسرائيل، حيث أمر الله موسى عليه السلام بأن يأمر قومه بذبح بقرة وضرب الميت بجزء منها ليتكلم ويكشف قاتله.\r\nعلاج مشكلات المجتمع المدني: نزلت الآيات الأولى لتبيين أصناف المجتمع (مؤمنين، كافرين، منافقين)، ورسم معالم الدولة الإسلامية.\r\nآيات القتال (آية 217): نزلت في شأن سرية عبد الله بن جحش والشهر الحرام، قوله تعالى: ﴿يَسْأَلُونَكَ عَنِ الشَّهْرِ الْحَرَامِ قِتَالٍ فِيهِ﴾.\r\nالطعن في قصة الآيات (آية 26): نزل قوله تعالى: ﴿إِنَّ اللَّهَ لا يَسْتَحْيِي أَنْ يَضْرِبَ مَثَلاً مَا بَعُوضَةً فَمَا فَوْقَهَا﴾ ردًا على المنافقين الذين استنكروا ضرب الأمثال بالبعوض.\r\nالاستخلاف وقصة طالوت وجالوت: نزلت كقصة استكمال لقصة استخلاف آدم عليه السلام لبيان مفهوم الخلافة في الأرض.\r\nقصة صهيب الرومي (آية 207): نزلت في شأن صهيب الرومي الذي باع ماله للمشركين ليخرج إلى المدينة، قوله تعالى: ﴿وَمِنَ النَّاسِ مَنْ يَشْرِي نَفْسَهُ ابْتِغَاءَ مَرْضَاةِ اللَّهِ﴾.\r\nالطواف بين الصفا والمروة (آية 158): نزلت لطمأنة المسلمين الذين كرهوا الطواف بينهما ظنًا منهم أنه من أعمال الجاهلية.	2026-03-27 00:33:24.392901+03	2026-03-27 00:33:24.392901+03	2026-03-27 00:33:24.392901+03
6	14	15	submitted	تمت الاجابة عليها جميعا	2026-03-27 00:37:51.413599+03	2026-03-27 00:37:51.413599+03	2026-03-27 00:37:51.413599+03
\.


--
-- Data for Name: teacher_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_assignments (id, teacher_id, academic_year_id, term, stage_id, grade_id, section_id, subject_id, created_at) FROM stdin;
1	2	2	1	1	1	1	1	2026-03-02 00:25:09.108938+03
2	2	2	1	1	1	1	17	2026-03-02 00:25:09.108938+03
4	1	1	1	1	2	23	1	2026-03-02 00:31:18.984661+03
5	1	1	1	1	2	23	2	2026-03-02 00:31:18.984661+03
6	1	1	1	1	2	23	3	2026-03-02 00:31:18.984661+03
7	1	1	1	1	2	23	7	2026-03-02 00:31:18.984661+03
8	1	1	1	1	2	23	8	2026-03-02 00:31:18.984661+03
9	1	1	1	1	2	23	9	2026-03-02 00:31:18.984661+03
10	1	1	1	1	2	23	15	2026-03-02 00:31:18.984661+03
11	1	1	1	1	2	23	16	2026-03-02 00:31:18.984661+03
12	1	1	1	1	2	23	17	2026-03-02 00:31:18.984661+03
13	1	1	1	1	2	23	18	2026-03-02 00:31:18.984661+03
14	1	1	1	1	4	28	9	2026-03-02 00:31:18.984661+03
15	1	1	1	1	5	31	1	2026-03-02 00:31:18.984661+03
16	1	1	1	1	5	31	3	2026-03-02 00:31:18.984661+03
17	1	1	1	1	5	31	7	2026-03-02 00:31:18.984661+03
18	1	1	1	1	5	31	8	2026-03-02 00:31:18.984661+03
19	1	1	1	1	5	31	9	2026-03-02 00:31:18.984661+03
20	1	1	1	1	5	31	15	2026-03-02 00:31:18.984661+03
21	1	1	1	1	5	31	16	2026-03-02 00:31:18.984661+03
22	1	1	1	1	5	31	17	2026-03-02 00:31:18.984661+03
23	1	1	1	1	5	31	18	2026-03-02 00:31:18.984661+03
24	1	1	1	2	7	4	1	2026-03-02 00:31:18.984661+03
25	1	1	1	2	7	4	2	2026-03-02 00:31:18.984661+03
26	1	1	1	2	7	4	3	2026-03-02 00:31:18.984661+03
27	1	1	1	2	7	4	7	2026-03-02 00:31:18.984661+03
28	1	1	1	2	7	4	8	2026-03-02 00:31:18.984661+03
29	1	1	1	2	7	4	9	2026-03-02 00:31:18.984661+03
30	1	1	1	2	7	4	15	2026-03-02 00:31:18.984661+03
31	1	1	1	2	7	4	16	2026-03-02 00:31:18.984661+03
32	1	1	1	2	7	4	17	2026-03-02 00:31:18.984661+03
33	1	1	1	2	7	4	18	2026-03-02 00:31:18.984661+03
34	2	1	1	1	1	1	1	2026-03-02 00:31:18.984661+03
35	2	1	1	1	1	1	3	2026-03-02 00:31:18.984661+03
36	2	1	1	1	1	1	7	2026-03-02 00:31:18.984661+03
37	2	1	1	1	1	1	8	2026-03-02 00:31:18.984661+03
38	2	1	1	1	1	1	15	2026-03-02 00:31:18.984661+03
39	2	1	1	1	1	1	16	2026-03-02 00:31:18.984661+03
40	2	1	1	1	1	1	17	2026-03-02 00:31:18.984661+03
41	2	1	1	1	1	1	18	2026-03-02 00:31:18.984661+03
42	2	1	1	1	1	1	19	2026-03-02 00:31:18.984661+03
43	2	1	1	1	2	23	19	2026-03-02 00:31:18.984661+03
44	2	1	1	1	3	25	9	2026-03-02 00:31:18.984661+03
46	2	2	1	1	1	1	2	2026-03-02 00:31:18.984661+03
47	2	2	1	1	1	1	3	2026-03-02 00:31:18.984661+03
48	2	2	1	1	1	1	7	2026-03-02 00:31:18.984661+03
49	2	2	1	1	1	1	8	2026-03-02 00:31:18.984661+03
50	2	2	1	1	1	1	9	2026-03-02 00:31:18.984661+03
51	2	2	1	1	1	1	15	2026-03-02 00:31:18.984661+03
52	2	2	1	1	1	1	16	2026-03-02 00:31:18.984661+03
54	2	2	1	1	1	1	18	2026-03-02 00:31:18.984661+03
55	2	2	1	1	1	1	19	2026-03-02 00:31:18.984661+03
56	2	4	1	1	1	1	16	2026-03-02 00:31:18.984661+03
57	2	4	1	1	1	1	19	2026-03-02 00:31:18.984661+03
58	3	1	1	1	3	25	3	2026-03-02 00:31:18.984661+03
59	3	1	1	1	4	28	2	2026-03-02 00:31:18.984661+03
60	3	1	1	1	4	28	3	2026-03-02 00:31:18.984661+03
61	4	1	1	1	3	25	8	2026-03-02 00:31:18.984661+03
62	4	1	1	1	4	28	7	2026-03-02 00:31:18.984661+03
63	4	4	1	1	1	1	2	2026-03-02 00:31:18.984661+03
64	6	1	1	1	3	25	17	2026-03-02 00:31:18.984661+03
65	6	1	1	1	4	28	1	2026-03-02 00:31:18.984661+03
66	6	4	1	1	1	1	8	2026-03-02 00:31:18.984661+03
67	6	4	1	1	1	1	15	2026-03-02 00:31:18.984661+03
68	7	1	1	1	3	25	7	2026-03-02 00:31:18.984661+03
69	7	1	1	1	4	28	17	2026-03-02 00:31:18.984661+03
70	7	1	1	1	4	28	18	2026-03-02 00:31:18.984661+03
71	7	4	1	1	1	1	3	2026-03-02 00:31:18.984661+03
72	7	4	1	1	1	1	7	2026-03-02 00:31:18.984661+03
73	8	1	1	1	3	25	18	2026-03-02 00:31:18.984661+03
74	8	1	1	1	4	28	8	2026-03-02 00:31:18.984661+03
75	8	4	1	1	1	1	1	2026-03-02 00:31:18.984661+03
76	9	1	1	1	3	25	16	2026-03-02 00:31:18.984661+03
77	9	4	1	1	1	1	9	2026-03-02 00:31:18.984661+03
78	10	1	1	1	4	28	16	2026-03-02 00:31:18.984661+03
79	10	4	1	1	1	1	18	2026-03-02 00:31:18.984661+03
80	11	1	1	1	3	25	1	2026-03-02 00:31:18.984661+03
81	11	4	1	1	1	1	17	2026-03-02 00:31:18.984661+03
82	12	1	1	1	3	25	15	2026-03-02 00:31:18.984661+03
83	12	1	1	1	4	28	15	2026-03-02 00:31:18.984661+03
84	12	1	1	1	5	31	2	2026-03-02 00:31:18.984661+03
85	13	1	1	1	1	1	2	2026-03-02 00:31:18.984661+03
86	13	1	1	1	3	25	2	2026-03-02 00:31:18.984661+03
3	1	2	1	1	1	1	9	2026-03-02 00:31:18.984661+03
\.


--
-- Data for Name: teacher_attendance_corrections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_attendance_corrections (id, entry_id, day_id, teacher_id, old_status, new_status, reason, corrected_by_user_id, corrected_at) FROM stdin;
1	1	1	2	present	absent	\N	1	2026-02-14 23:57:56.663113+03
2	1	1	2	absent	present	\N	1	2026-02-14 23:57:58.505754+03
3	2	1	1	present	absent	\N	1	2026-02-14 23:58:00.054266+03
4	2	1	1	absent	present	\N	1	2026-02-14 23:58:00.651678+03
5	3	1	12	present	absent	\N	1	2026-02-15 00:12:59.090415+03
6	2	1	1	present	absent	\N	1	2026-02-15 00:12:59.538759+03
7	1	1	2	present	absent	\N	1	2026-02-15 00:12:59.978559+03
8	1	1	2	absent	present	\N	1	2026-02-15 00:38:56.169866+03
9	1	1	2	present	absent	\N	1	2026-02-15 00:38:57.054266+03
10	1	1	2	absent	present	\N	1	2026-02-15 00:38:59.73283+03
11	1	1	2	present	absent	\N	1	2026-02-15 00:39:01.143402+03
12	1	1	2	absent	present	\N	1	2026-02-15 00:39:06.746997+03
13	4	3	1	present	absent	\N	1	2026-02-15 20:31:24.518433+03
\.


--
-- Data for Name: teacher_attendance_days; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_attendance_days (id, attendance_date, academic_year_id, is_locked, locked_by_user_id, locked_at, created_by_user_id, created_at, updated_at) FROM stdin;
1	2026-02-14	2	f	\N	\N	1	2026-02-14 23:57:23.116727+03	2026-02-15 00:05:31.20893+03
2	2026-02-12	2	f	\N	\N	1	2026-02-15 00:41:36.273212+03	\N
3	2026-02-15	2	f	\N	\N	1	2026-02-15 18:57:33.591705+03	\N
4	2026-02-20	2	t	1	2026-02-21 01:01:58.660836+03	1	2026-02-21 01:01:57.109124+03	2026-02-21 01:01:58.660836+03
\.


--
-- Data for Name: teacher_attendance_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_attendance_entries (id, day_id, teacher_id, status, method, scanned_card_uid, notes, recorded_by_user_id, recorded_at, created_at, updated_at, scanned_card_id) FROM stdin;
3	1	12	absent	manual	\N	\N	1	2026-02-15 00:12:52.766139+03	2026-02-15 00:12:52.766139+03	2026-02-15 00:12:59.090415+03	\N
2	1	1	absent	manual	\N	\N	1	2026-02-14 23:57:48.913615+03	2026-02-14 23:57:48.913615+03	2026-02-15 00:12:59.538759+03	\N
1	1	2	present	manual	\N	\N	1	2026-02-14 23:57:40.455469+03	2026-02-14 23:57:40.455469+03	2026-02-15 00:39:06.746997+03	\N
4	3	1	present	scan	TT-F1F6364D7F9EFF3F675F	\N	1	2026-02-15 20:32:23.22829+03	2026-02-15 20:18:12.401043+03	2026-02-15 20:32:23.22829+03	\N
\.


--
-- Data for Name: teacher_attendance_scan_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_attendance_scan_events (id, day_id, teacher_id, raw_code, normalized_code, source, ip_address, user_agent, created_by_user_id, created_at, card_id) FROM stdin;
1	1	\N	TT-ZJPLVF2YDKJUCRH3	TT-ZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:18:42.460095+03	\N
3	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:16.116855+03	\N
4	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:23.050551+03	\N
5	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:23.499613+03	\N
6	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:24.019759+03	\N
7	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:34.241169+03	\N
8	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:34.351467+03	\N
9	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:34.552216+03	\N
10	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:34.899411+03	\N
11	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:35.393142+03	\N
12	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:35.618078+03	\N
13	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:35.808898+03	\N
14	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:35:35.981478+03	\N
15	1	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 00:41:22.888985+03	\N
16	3	\N	TTZJPLVF2YDKJUCRH3	TTZJPLVF2YDKJUCRH3	scanner	\N	\N	1	2026-02-15 18:57:33.591705+03	\N
17	3	\N	TTEWUCINBOVUJ1677N	TTEWUCINBOVUJ1677N	scanner	\N	\N	1	2026-02-15 19:10:47.050707+03	\N
18	3	\N	TTEWUCINBOVUJ1677N	TTEWUCINBOVUJ1677N	scanner	\N	\N	1	2026-02-15 19:11:21.655984+03	\N
19	3	\N	TTEWUCINBOVUJ1677N	TTEWUCINBOVUJ1677N	scanner	\N	\N	1	2026-02-15 19:11:22.097775+03	\N
20	3	\N	TTEWUCINBOVUJ1677N	TTEWUCINBOVUJ1677N	scanner	\N	\N	1	2026-02-15 19:11:22.282242+03	\N
21	3	\N	TTEWUCINBOVUJ1677N	TTEWUCINBOVUJ1677N	scanner	\N	\N	1	2026-02-15 19:11:22.433608+03	\N
22	3	\N	TTIOFYOBYZSIDXQFR	TTIOFYOBYZSIDXQFR	scanner	\N	\N	1	2026-02-15 19:47:56.983685+03	\N
23	3	\N	RESOLVETEACHERFROMCODE	RESOLVETEACHERFROMCODE	scanner	\N	\N	1	2026-02-15 20:11:46.746462+03	\N
24	3	1	TT-3B07AB2A435EDFF0ABCC	TT3B07AB2A435EDFF0ABCC	scanner	\N	\N	1	2026-02-15 20:18:12.401043+03	\N
25	3	1	TT-3B07AB2A435EDFF0ABCC	TT3B07AB2A435EDFF0ABCC	scanner	\N	\N	1	2026-02-15 20:18:35.624425+03	\N
26	3	1	TT-F1F6364D7F9EFF3F675F	TTF1F6364D7F9EFF3F675F	scanner	\N	\N	1	2026-02-15 20:31:19.586445+03	\N
27	3	1	TT-F1F6364D7F9EFF3F675F	TTF1F6364D7F9EFF3F675F	scanner	\N	\N	1	2026-02-15 20:32:23.22829+03	\N
\.


--
-- Data for Name: teacher_attendance_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_attendance_settings (id, duty_start_time, grace_minutes, allow_mark_absent, lock_after_minutes, created_by_user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: teacher_barcode_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_barcode_tokens (teacher_id, token_hash, expires_at, created_at, updated_at) FROM stdin;
1	9c68eeada8dfdf975fc8154e530a69e5f911d009d0d53cee0d493a95b2596cea	2026-03-29 10:32:50.218+03	2026-02-14 23:23:20.955909+03	2026-03-29 10:27:40.230681+03
13	b7cea2e90e1dfe897508197fb74ff7accdf9e4d1fc5e98e07aa72b77d8469c22	2026-02-21 23:08:04.217+03	2026-02-16 17:10:01.166197+03	2026-02-21 23:02:54.220505+03
\.


--
-- Data for Name: teacher_cards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_cards (id, teacher_id, card_uid, card_type, is_active, issued_at, revoked_at, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: teacher_lesson_presence; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_lesson_presence (id, presence_date, teacher_id, timetable_entry_id, attendance_session_id, status, permission_request_id, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: teacher_permission_request_slots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_permission_request_slots (id, permission_request_id, timetable_entry_id) FROM stdin;
\.


--
-- Data for Name: teacher_permission_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_permission_requests (id, teacher_id, request_date, scope, status, reason_text, notes, requested_at, decided_at, decided_by_user_id, decision_note, created_at, updated_at) FROM stdin;
1	1	2026-02-14	full_day	rejected	\N	\N	2026-02-14 23:08:34.139412+03	2026-02-15 22:19:35.53058+03	1	\N	2026-02-14 22:52:20.043064+03	2026-02-15 22:19:35.53058+03
5	1	2026-02-15	full_day	approved	\N	\N	2026-02-15 21:50:41.338774+03	2026-02-15 22:19:42.809372+03	1	\N	2026-02-15 21:50:41.338774+03	2026-02-15 22:19:42.809372+03
7	1	2026-02-16	slots	approved	مريض	ارجو القبول	2026-02-16 01:16:12.649282+03	2026-02-16 01:16:53.396426+03	1	تم القبول الله يشفيك	2026-02-16 01:15:50.489404+03	2026-02-16 01:16:53.396426+03
6	1	2026-02-15	slots	approved	\N	\N	2026-02-16 01:36:18.59229+03	2026-02-16 02:11:19.303692+03	1	\N	2026-02-15 22:20:08.424865+03	2026-02-16 02:11:19.303692+03
8	13	2026-02-16	slots	approved	\N	\N	2026-02-16 17:31:02.303225+03	2026-02-16 17:31:30.505778+03	1	\N	2026-02-16 17:31:02.303225+03	2026-02-16 17:31:30.505778+03
9	13	2026-02-16	slots	approved	\N	\N	2026-02-17 00:14:01.225777+03	2026-02-17 00:14:38.286443+03	1	\N	2026-02-16 18:07:57.560184+03	2026-02-17 00:14:38.286443+03
10	13	2026-02-16	slots	approved	\N	\N	2026-02-17 00:16:41.964748+03	2026-02-17 00:17:09.465035+03	1	\N	2026-02-17 00:16:41.964748+03	2026-02-17 00:17:09.465035+03
11	13	2026-02-16	slots	approved	\N	\N	2026-02-17 00:27:43.849725+03	2026-02-17 00:28:15.319967+03	1	\N	2026-02-17 00:27:43.849725+03	2026-02-17 00:28:15.319967+03
12	13	2026-02-16	slots	approved	\N	\N	2026-02-17 00:41:11.776004+03	2026-02-17 00:41:31.429363+03	1	\N	2026-02-17 00:41:11.776004+03	2026-02-17 00:41:31.429363+03
13	13	2026-02-20	slots	approved	\N	\N	2026-02-20 21:59:11.911788+03	2026-02-20 22:00:17.255359+03	1	\N	2026-02-20 21:48:26.733251+03	2026-02-20 22:00:17.255359+03
14	13	2026-02-22	slots	approved	\N	\N	2026-02-20 22:54:37.654992+03	2026-02-20 22:56:10.914545+03	1	\N	2026-02-20 22:54:37.654992+03	2026-02-20 22:56:10.914545+03
15	13	2026-02-23	slots	approved	\N	\N	2026-02-21 01:11:01.158335+03	2026-02-21 01:11:26.084548+03	1	\N	2026-02-21 01:11:01.158335+03	2026-02-21 01:11:26.084548+03
16	1	2026-02-20	slots	approved	\N	\N	2026-02-21 01:24:56.715867+03	2026-02-21 01:26:23.681329+03	1	\N	2026-02-21 01:24:56.715867+03	2026-02-21 01:26:23.681329+03
17	1	2026-02-21	slots	approved	مريض	\N	2026-02-21 21:41:31.434287+03	2026-02-21 21:43:03.706283+03	1	\N	2026-02-21 21:41:31.434287+03	2026-02-21 21:43:03.706283+03
\.


--
-- Data for Name: teacher_subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teacher_subjects (id, teacher_id, subject_id, is_active, created_at, updated_at, school_id) FROM stdin;
92	3	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
12	3	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
52	3	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
62	3	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
82	3	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
72	3	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
42	3	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
32	3	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
22	3	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
2	3	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
93	4	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
13	4	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
53	4	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
63	4	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
83	4	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
73	4	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
43	4	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
33	4	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
23	4	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
3	4	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
94	6	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
14	6	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
54	6	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
64	6	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
84	6	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
74	6	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
44	6	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
34	6	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
24	6	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
4	6	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
95	8	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
15	8	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
55	8	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
65	8	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
85	8	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
75	8	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
45	8	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
35	8	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
25	8	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
5	8	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
96	9	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
16	9	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
56	9	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
66	9	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
86	9	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
76	9	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
46	9	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
36	9	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
26	9	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
6	9	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
97	10	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
17	10	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
57	10	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
67	10	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
87	10	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
77	10	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
47	10	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
37	10	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
27	10	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
7	10	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
98	11	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
18	11	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
58	11	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
68	11	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
88	11	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
78	11	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
48	11	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
38	11	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
28	11	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
8	11	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
100	7	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
60	7	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
20	7	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
70	7	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
90	7	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
80	7	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
50	7	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
40	7	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
30	7	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
10	7	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
164	5	9	t	2026-02-21 21:21:11.3265+03	2026-02-21 21:21:11.3265+03	1
91	2	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
11	2	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
51	2	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
61	2	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
109	2	19	t	2026-01-14 22:13:06.704627+03	2026-01-17 16:28:48.060886+03	1
81	2	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
71	2	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
41	2	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
31	2	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
21	2	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
1	2	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
99	1	18	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:32.277923+03	1
19	1	2	t	2026-01-12 23:39:31.683446+03	2026-02-02 00:45:13.519281+03	1
59	1	9	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:11.3265+03	1
111	1	19	f	2026-01-14 23:30:33.462953+03	2026-01-17 16:28:48.060886+03	1
69	1	15	t	2026-01-12 23:39:31.683446+03	2026-02-21 21:21:22.671846+03	1
89	1	17	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
79	1	16	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
49	1	8	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
39	1	7	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
29	1	3	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
9	1	1	t	2026-01-12 23:39:31.683446+03	2026-01-12 23:39:31.683446+03	1
177	12	15	t	2026-02-21 21:21:22.671846+03	2026-02-21 21:21:22.671846+03	1
165	12	9	t	2026-02-21 21:21:11.3265+03	2026-02-21 21:21:11.3265+03	1
132	12	2	t	2026-01-24 15:04:08.659222+03	2026-02-02 00:45:13.519281+03	1
188	13	18	t	2026-02-21 21:21:32.277923+03	2026-02-21 21:21:32.277923+03	1
144	13	2	t	2026-02-02 00:45:13.519281+03	2026-02-02 00:45:13.519281+03	1
163	13	9	t	2026-02-21 21:21:11.3265+03	2026-02-21 21:21:11.3265+03	1
\.


--
-- Data for Name: teachers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teachers (id, user_id, full_name, phone, is_active, created_at, updated_at, school_id) FROM stdin;
3	\N	خالد علي	770000002	t	2026-01-02 23:56:04.245799+03	2026-01-02 23:56:04.245799+03	1
4	\N	سامي عبدالله	770000003	t	2026-01-02 23:56:04.245799+03	2026-01-02 23:56:04.245799+03	1
6	\N	ياسر صالح	770000005	t	2026-01-02 23:56:04.245799+03	2026-01-02 23:56:04.245799+03	1
8	\N	ناصر حسين	770000007	t	2026-01-02 23:56:04.245799+03	2026-01-02 23:56:04.245799+03	1
9	\N	فهد إبراهيم	770000008	t	2026-01-02 23:56:04.245799+03	2026-01-02 23:56:04.245799+03	1
10	\N	مروان جمال	770000009	t	2026-01-02 23:56:04.245799+03	2026-01-02 23:56:04.245799+03	1
11	\N	رائد محمود	770000010	t	2026-01-02 23:56:04.245799+03	2026-01-02 23:56:04.245799+03	1
7	\N	حسن عمر	770000006	t	2026-01-02 23:56:04.245799+03	2026-01-14 21:58:55.05699+03	1
5	\N	ماهر أحمد	770000004	t	2026-01-02 23:56:04.245799+03	2026-01-14 21:58:55.485174+03	1
2	\N	أحمد محمد	770000001	t	2026-01-02 23:56:04.245799+03	2026-01-14 21:58:55.872847+03	1
1	32	الأستاذ أحمد محمد	777777777	t	2025-12-29 22:19:03.198194+03	2026-01-14 21:58:57.059109+03	1
12	46	امين عبده محمد غانم البعداني	770398951	t	2026-01-24 15:03:28.196704+03	2026-01-24 15:03:28.196704+03	1
13	48	علي احمد قاسم النوري	575257386	t	2026-02-02 00:44:16.819676+03	2026-02-02 00:44:16.819676+03	1
\.


--
-- Data for Name: timetable_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.timetable_entries (id, timetable_id, day_of_week, period_id, subject_id, teacher_id, room, notes, created_at, updated_at, school_id) FROM stdin;
479	1	7	9	2	13	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
478	1	7	8	2	13	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
477	1	7	3	2	13	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
476	1	7	2	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
475	1	7	1	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
474	1	5	11	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
473	1	5	10	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
472	1	5	8	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
471	1	5	3	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
470	1	5	1	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
469	1	4	2	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
468	1	4	1	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
467	1	3	11	2	13	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
466	1	3	10	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
465	1	3	9	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
464	1	3	8	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
463	1	3	3	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
462	1	3	2	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
461	1	3	1	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
460	1	2	9	2	13	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
459	1	2	8	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
458	1	2	3	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
457	1	2	1	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
456	1	1	21	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
455	1	1	20	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
454	1	1	8	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
453	1	1	3	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
452	1	1	2	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
451	1	1	1	9	1	\N	\N	2026-03-03 23:43:38.262649+03	2026-03-03 23:43:38.262649+03	3
236	4	1	10	2	1	\N	\N	2026-02-07 14:15:26.577158+03	2026-02-07 14:15:26.577158+03	3
235	4	1	9	15	1	\N	\N	2026-02-07 14:15:26.577158+03	2026-02-07 14:15:26.577158+03	3
234	4	6	20	9	1	\N	\N	2026-02-07 14:15:26.577158+03	2026-02-07 14:15:26.577158+03	3
233	4	6	1	9	1	\N	\N	2026-02-07 14:15:26.577158+03	2026-02-07 14:15:26.577158+03	3
232	4	3	35	15	1	\N	\N	2026-02-07 14:15:26.577158+03	2026-02-07 14:15:26.577158+03	3
36	6	2	20	2	12	\N	\N	2026-01-24 15:07:11.64089+03	2026-01-24 17:08:43.071373+03	3
35	6	1	1	2	12	\N	\N	2026-01-24 15:07:11.64089+03	2026-01-24 17:08:43.071373+03	3
558	2	7	1	9	1	\N	\N	2026-03-27 00:29:52.993335+03	2026-03-27 00:29:52.993335+03	3
557	2	6	1	9	1	\N	\N	2026-03-27 00:29:52.993335+03	2026-03-27 00:29:52.993335+03	3
556	2	5	1	9	1	\N	\N	2026-03-27 00:29:52.993335+03	2026-03-27 00:29:52.993335+03	3
555	2	2	2	17	2	\N	\N	2026-03-27 00:29:52.993335+03	2026-03-27 00:29:52.993335+03	3
554	2	1	2	9	1	\N	\N	2026-03-27 00:29:52.993335+03	2026-03-27 00:29:52.993335+03	3
553	2	1	1	9	1	\N	\N	2026-03-27 00:29:52.993335+03	2026-03-27 00:29:52.993335+03	3
351	12	1	34	9	1	\N	\N	2026-02-21 21:49:20.217822+03	2026-02-21 21:49:20.217822+03	3
350	12	1	35	9	1	\N	\N	2026-02-21 21:49:20.217822+03	2026-02-21 21:49:20.217822+03	3
349	12	1	8	17	7	\N	\N	2026-02-21 21:49:20.217822+03	2026-02-21 21:49:20.217822+03	3
348	12	1	3	15	12	\N	\N	2026-02-21 21:49:20.217822+03	2026-02-21 21:49:20.217822+03	3
347	12	1	2	18	7	\N	\N	2026-02-21 21:49:20.217822+03	2026-02-21 21:49:20.217822+03	3
346	12	1	1	3	3	\N	\N	2026-02-21 21:49:20.217822+03	2026-02-21 21:49:20.217822+03	3
238	8	1	11	16	1	\N	\N	2026-02-07 14:16:30.601138+03	2026-02-07 14:16:30.601138+03	3
237	8	5	21	15	1	\N	\N	2026-02-07 14:16:30.601138+03	2026-02-07 14:16:30.601138+03	3
\.


--
-- Data for Name: timetable_overrides; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.timetable_overrides (id, timetable_id, date, day_of_week, period_id, type, subject_id, teacher_id, room, notes, exam_title, exam_kind, exam_total, created_at, updated_at, status, school_id) FROM stdin;
19	1	2026-03-03	4	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-03 23:22:45.962346+03	2026-03-03 23:22:45.962346+03	draft	3
18	1	2026-03-02	3	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-03 23:21:17.101829+03	2026-03-03 23:21:17.101829+03	draft	3
7	1	2026-02-28	1	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-02 23:01:21.782296+03	2026-03-03 23:49:14.344096+03	draft	3
13	2	2026-03-03	4	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-03 22:30:47.779206+03	2026-03-03 23:44:56.570705+03	draft	3
27	2	2026-03-01	2	2	exam	9	1	\N	\N	\N	monthly	\N	2026-03-03 23:51:32.581798+03	2026-03-03 23:51:32.581798+03	draft	3
29	2	2026-02-28	1	3	lesson	9	1	\N	\N	\N	\N	\N	2026-03-04 00:30:36.59579+03	2026-03-04 00:30:36.59579+03	draft	3
30	2	2026-02-28	1	8	lesson	9	1	\N	\N	\N	\N	\N	2026-03-04 00:30:49.330496+03	2026-03-04 00:30:49.330496+03	draft	3
8	2	2026-02-28	1	1	lesson	9	1	\N	\N	\N	\N	\N	2026-03-02 23:16:32.474112+03	2026-03-04 00:32:58.571632+03	draft	3
28	2	2026-02-28	1	2	exam	9	1	\N	\N	\N	monthly	\N	2026-03-04 00:30:24.281139+03	2026-03-04 22:39:31.654643+03	draft	3
38	2	2026-03-21	1	3	lesson	9	1	\N	\N	\N	\N	\N	2026-03-25 00:39:54.506662+03	2026-03-25 00:39:54.506662+03	draft	3
59	2	2026-03-26	6	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-26 00:04:51.059765+03	2026-03-26 00:04:51.059765+03	draft	3
42	2	2026-03-20	5	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-25 23:19:15.838507+03	2026-03-27 00:29:52.2305+03	draft	3
39	2	2026-03-20	1	3	lesson	9	1	\N	\N	\N	\N	\N	2026-03-25 22:07:59.934608+03	2026-03-27 00:29:52.262456+03	draft	3
41	2	2026-03-21	5	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-25 22:08:00.061006+03	2026-03-27 00:29:52.293661+03	draft	3
49	2	2026-03-22	5	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-25 23:22:49.066989+03	2026-03-27 00:29:52.329611+03	draft	3
44	2	2026-03-23	5	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-25 23:19:15.906506+03	2026-03-27 00:29:52.364557+03	draft	3
40	2	2026-03-24	5	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-25 22:08:00.002544+03	2026-03-27 00:29:52.404209+03	draft	3
35	2	2026-03-25	6	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-25 00:36:38.762581+03	2026-03-27 00:29:52.435347+03	draft	3
10	2	2026-03-02	3	1	lesson	15	1	\N	\N	\N	\N	\N	2026-03-02 23:39:08.654621+03	2026-03-02 23:39:08.654621+03	draft	3
67	2	2026-03-27	7	1	exam	9	1	\N	\N	\N	monthly	\N	2026-03-27 00:29:52.474402+03	2026-03-27 00:29:52.474402+03	draft	3
11	2	2026-03-02	3	2	exam	9	1	\N	\N	\N	monthly	\N	2026-03-02 23:39:26.377399+03	2026-03-02 23:39:26.377399+03	draft	3
12	2	2026-03-03	4	2	exam	9	1	\N	\N	شهري	monthly	\N	2026-03-03 22:24:16.945985+03	2026-03-03 22:24:16.945985+03	draft	3
\.


--
-- Data for Name: timetables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.timetables (id, academic_year_id, stage_id, grade_id, section_id, term, status, created_by, created_at, updated_at, school_id) FROM stdin;
1	1	1	1	1	1	published	1	2026-01-17 17:30:24.731265+03	2026-03-03 23:49:14.344096+03	3
3	2	1	2	23	1	draft	1	2026-01-17 22:31:31.822865+03	2026-01-17 22:31:31.822865+03	3
7	2	2	7	4	1	draft	1	2026-02-05 01:07:55.329391+03	2026-02-05 01:07:55.329391+03	3
13	2	1	4	28	1	draft	1	2026-02-21 21:47:41.417106+03	2026-02-21 21:47:41.417106+03	3
4	1	1	2	23	1	published	1	2026-01-19 16:15:04.832457+03	2026-02-07 14:15:27.104958+03	3
5	1	1	4	30	1	draft	1	2026-01-22 14:41:58.348271+03	2026-01-22 14:41:58.348271+03	3
9	1	1	3	25	1	draft	1	2026-02-11 23:26:49.826351+03	2026-02-11 23:26:49.826351+03	3
10	2	1	3	25	1	draft	1	2026-02-11 23:26:56.841286+03	2026-02-11 23:26:56.841286+03	3
15	3	1	1	1	1	draft	1	2026-03-25 00:38:32.17223+03	2026-03-25 00:38:32.17223+03	3
11	1	1	1	2	1	draft	1	2026-02-16 17:11:10.94635+03	2026-02-16 17:11:10.94635+03	3
6	1	1	5	31	1	published	1	2026-01-24 15:06:38.990696+03	2026-01-24 15:07:12.056479+03	3
2	2	1	1	1	1	published	1	2026-01-17 17:30:29.214975+03	2026-03-27 00:29:53.008513+03	3
12	1	1	4	28	1	published	1	2026-02-21 21:22:35.696262+03	2026-02-21 21:49:38.248151+03	3
8	1	2	7	4	1	draft	1	2026-02-05 01:08:44.525397+03	2026-03-02 01:35:06.891633+03	3
14	1	1	6	34	1	draft	1	2026-03-02 01:47:24.898276+03	2026-03-02 01:47:24.898276+03	3
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, user_id, role_id) FROM stdin;
23	18	1
25	19	2
28	22	3
30	24	3
33	23	4
34	27	4
35	28	3
36	29	3
37	30	3
39	31	4
40	32	2
41	33	4
42	34	3
43	35	3
44	36	3
45	37	2
48	39	27
50	40	28
51	38	26
52	41	28
53	42	2
54	43	3
55	44	3
56	45	3
57	46	2
58	48	2
59	49	3
60	50	4
61	51	3
62	1	1
63	52	3
64	53	3
65	54	3
66	55	29
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, username, phone, password_hash, status, created_at, updated_at, token_version, school_id) FROM stdin;
46	امين عبده محمد غانم البعداني	ameen770398951@gamil.com	ameen770	770398951	$2b$10$B5QlsUrr6xXcnLa0Gug8Juj/Fb4wuRJCr7ovqdd/2oveb3pbwiA42	active	2026-01-24 15:03:28.196704	2026-01-24 15:03:28.196704	0	1
27	احمد البعجاني	ahmeds@gmail.com	ahmeds	321	$2b$10$1aCNG4fxXa05nedWQs06d.ydE.a49APbrqLpL7he/brmTCoY0RWxW	active	2025-12-24 23:30:16.477117	2025-12-24 23:30:16.477117	1	1
28	عبدالله البعداني	abdullahameen@school.com	abdullahameen	123	$2b$10$gExlKHgmjmZfy7SGxLD4yeku7yLt7kP1zGzVsP4cpPCGHR6tkNm9i	active	2025-12-24 23:30:16.477117	2025-12-24 23:30:16.477117	1	1
29	خالد وليد	ali@school.com	ali	7725424554776732	$2b$10$qY9ZqX.CGcN0f.mNSKJ4W.7LpyS8Ufn85RgcoN1ktS3kdr9zkK24S	active	2025-12-25 17:16:24.282994	2025-12-25 17:16:24.282994	1	1
19	احمد بداح	ahmed@gmail.com	ahmed	1010	$2b$10$3wOxl990k5KxuaWcVtcAb./ycMtUqG4yRO58YXaf7Bp3xnRJ2F1vS	active	2025-12-09 17:29:15.490894	2025-12-09 17:29:15.490894	1	1
20	وسيم الجنيد	waseem@gmail.com	waseem	7474	$2b$10$YjIt7Im.dyVSc1NTd14J6.gvnAy67MhJI4G8DbI2E5s1xwm8K/Ece	active	2025-12-16 18:15:16.049345	2025-12-16 18:15:16.049345	2	1
38	عزالدين النوعة	azo@gmail.com	azo	8925465154	$2b$10$2oLYRQXk/jnhncZQ0nKGJefuoL7ydM97ac0JoQWz4NymyZxezPR7a	active	2026-01-09 00:59:12.463028	2026-01-09 00:59:12.463028	3	1
37	اسلام امين  بعده البعداين	eslam@gmail.com	eslam	101010	$2b$10$w32p8PSiNk0GZqDi3NCwPe7GdC7QyZSB5aBw/H7x2Vw2ZkVY4dGbi	active	2026-01-09 00:29:14.15945	2026-01-09 00:29:14.15945	1	1
30	AHMED AL BAADANI	aboood@gmail.com	abood	5252	$2b$10$WOFqiy5z6p17Vqwyshx3y.u7GUkv0lcoXXycWfJOsR8PSBS5HbVuK	active	2025-12-29 14:49:24.88615	2025-12-29 15:10:35.131809	3	1
21	امين البعداني	ameen@gmail.com	ameen	4564645654654	$2b$10$EVhrVimZxe4JsHOVlGbSDOXtn7FNotdO3L5XAJe5G7e5oQht1D5h6	active	2025-12-19 01:01:18.947845	2025-12-19 01:01:18.947845	1	1
22	عبدالله امين عبده محمد البعداني	abdullah@school.com	abdullah	7725424554	$2b$10$vHGTaxQS3JJXiqg/g52FQ.qNsIlvJhJfyiggqY6MobSb2/n19bdwS	active	2025-12-19 01:01:18.947845	2025-12-19 01:01:18.947845	1	1
23	امين البعداني	parent@gmail.com	parent	4564645654654	$2b$10$mtD3IPq09EGyPPWXWh.ewOC2N2IQRZWPbMALM62O8U7cH1KlkyrqG	active	2025-12-19 01:09:59.384745	2025-12-19 01:09:59.384745	1	1
31	امين البعداني	ameens@gmail.com	aameen	770398951	$2b$10$n6SRXO.YZaxR6iQufPHQpeSE/Wx5eU9sqhIwAjnxvPmDgI02m/ByO	active	2025-12-29 16:32:42.981669	2025-12-29 16:32:42.981669	1	1
24	عبدالله امين عبده محمد البعداني	father@school.com	father	7725424554	$2b$10$lOVI2b87EnvE0gZn7i2Ol.9X0ecbHxn7am669xcFzfBivxzqfusUq	active	2025-12-19 01:09:59.384745	2025-12-19 01:09:59.384745	1	1
25	امين البعدانيjb	parentt@gmail.com	parentt	456464565465454	$2b$10$yQvww.EC.Lfj4qcQVIT2bO5cw/HQAaLswXf2uf4XoTDbbB9XL0BLS	active	2025-12-19 15:18:07.64887	2025-12-19 15:18:07.64887	1	1
33	وليد الجنيد	waleed@gmail.com	waleed	772611048	$2b$10$rxu06QNQxk58cqU3bd04.uMr8atyqQvIFNBcfmJTR.CM11kgVAJpa	active	2026-01-01 17:50:50.016063	2026-01-01 17:50:50.016063	1	1
34	خالد وليد محمد عبدالحمن الجنيد	khaled@gmail.com	khaled	7725424554211	$2b$10$4nhxFP62PKGs8iLrAMu0Ge3tUpWPMdyy71qoMaIZJbewsGaZJttkC	active	2026-01-01 17:50:50.016063	2026-01-01 17:50:50.016063	1	1
35	مهند وليد الجنيد	mohaned@gmail.com	mohaned	22323213213	$2b$10$Etong2rz6xMs1vJTGmVdCOHhMdrADCZvDqruW5prbmbLCigsbTjvq	active	2026-01-03 00:56:47.189827	2026-01-03 00:56:47.189827	1	1
36	هلا وليد الجنيد	hala@gmail.com	hala	7725424554213	$2b$10$gFsaE6MyimT0XjcPXkhU5.fTMBV.OpuHyRayrbCy3q5X8ioU.N52e	active	2026-01-03 02:14:20.677612	2026-01-03 02:14:20.677612	1	1
39	جلال القعطبي	jalal@gmail.com	jalal	786451324	$2b$10$YP11.3A9eDrluE4LkXpE5.j1YkPVlChTgBYYL7QE4nUYWYWLCItjS	active	2026-01-09 01:05:20.002034	2026-01-09 01:05:20.002034	1	1
49	سعيد علي قاسم نور	saeed@gmail.com	saeed	7725424554454	$2b$10$9dMxK6RGhz9ra9hC1mZjueuRMVxHExM0jOCVD8PB/SPKW1Xpga97q	active	2026-02-11 23:29:27.733931	2026-02-11 23:29:27.733931	1	1
41	ناصر حسين	naser@gmail.com	naser	770000007	$2b$10$SiTHvy3W7f7N5wzRMjV/oucLoWimefDRUgTDdRFJ.1kGfkc3fpAUO	active	2026-01-11 16:17:30.392008	2026-01-11 16:17:30.392008	4	1
48	علي احمد قاسم النوري	aliali@gmail.com	aliali	575257386	$2b$10$X5R31grkYBLNtp0OgEFgu./vXa1BxtBQ7EDnaVNO9cZe9EbVDDAy.	active	2026-02-02 00:44:16.819676	2026-02-02 00:44:16.819676	0	1
40	تركي علي احمم\\	trky@gmail.com	trky	4434433344343	$2b$10$D6MpVT/kPQvNVPVU62/Fn.qqpw0j.O4hXb1aXrxlperlmXlizOydG	active	2026-01-09 01:51:42.596513	2026-01-09 01:51:42.596513	2	1
50	امين عبده محمد غانم البعداني البعداني	ameenalbadani@gmail.com	ameenalbadani	770398951	$2b$10$TqFXLrUAGpNFO.273MLGR.eF/v4eeTM39lX.yo4XNz8Y6r41ncXvq	active	2026-02-21 21:19:37.845714	2026-02-21 21:19:37.845714	1	1
42	احمد سعيد عبود	ahmed78@gmail.com	ahmed saeed	312323	$2b$10$Ui4ErnmqMU0zQtJp.7lT9uB0W9V3KhKgSpISFQ9bGInSkFx4MraU6	active	2026-01-12 13:59:16.182742	2026-01-12 13:59:16.182742	1	1
51	عبدالرحمن امين عبدة محمد غانم البعداني	abdelrhman@gmail.com	abdelrhman	77254245544545	$2b$10$mFwQrUc7j1djbvXCY9gxlOZeYoNHii5oEoix9VBsUI7jN0ff8bDYm	active	2026-02-21 21:19:37.845714	2026-02-21 21:19:37.845714	1	1
53	اسلام امين عبده محمد البعداني	eslamm@gmail.com	eslamm	1236546456	$2b$10$E35Pwah76bslKWwD3tTj9.d3OF8wxMaVRcNhkTbRJx4ScTHUBm83q	active	2026-03-10 22:12:12.215276	2026-03-10 22:12:12.215276	1	1
54	يوسف امين البعداني	yosif@gmail.com	yosif	7725424554776732434	$2b$10$INzEvk4wv7gDLguM7y2sOOo60KgCRbwJOIBN2SYZ/pAbIWN20/9BS	active	2026-03-10 23:47:13.012856	2026-03-10 23:47:13.012856	1	1
32	ali	ayman@gmail.com	ayman	777920256	$2b$10$Fm253StX5hRsOPJoMyNuoObOxzfywgfpPGCmr78fhFRj0RNa8R37W	active	2025-12-31 00:05:05.972949	2025-12-31 00:05:05.972949	7	1
43	عبدالله امين عبده محمد غانم البعداني	abdullah7700@gmail.com	abdullah7700	77254245544432	$2b$10$I2xWsfA40Qobtx9YAzUXoeBRmY1uWfnYLNyAdyrdUTlmRyL3K.0Wy	active	2026-01-17 22:37:44.050039	2026-01-17 22:37:44.050039	1	1
44	اين عليقاسم الجابري	qasem@gmail.com	qasem	772542455443543	$2b$10$uM82X9WMFRi71B/kPmEEMO6NeLFDsoqFnlzUvOHvOxiUkK.FXzlF2	active	2026-01-19 16:14:27.196664	2026-01-19 16:14:27.196664	1	1
52	محمد علي احمد الفاتح	mohamed@gmail.com	mohamed	772542455445656	$2b$10$1IkEcuXwqTyuxw/EKnNcleyc5mHfQTKT1AKfhvZlwcjUa3/QWIDJe	active	2026-03-04 00:29:32.668869	2026-03-04 00:29:32.668869	1	1
45	امجد علي احمد الكامل	amjad@gmail.com	amjad	772542455423	$2b$10$3FXr85dMcH8VbLXuoqNas./YQ2Yl4qqctS6PbdWYCStLBpPulYjUC	active	2026-01-19 16:28:08.508173	2026-01-19 16:28:08.508173	1	1
18	عدي نعمان	oday@gmail.com	oday	773115768	$2b$10$92JsXLBK4RY6iVdQunmQyusG8osENrbNZ7tsVleFD4MEwzPhlgWMe	active	2025-12-07 20:59:50.458117	2025-12-07 20:59:50.458117	20	1
1	الإدارة	admin@gmail.com	admin	770020496	$2b$10$fHom/Iwi7sO.vI7rFW/.6eW8qG9BCd4zbHwBU/g8DDAgRkk21ywoy	active	2025-11-29 05:13:09.181372	2025-12-08 14:35:10.278837	26	1
55	مدير النور	admin@alnoor.com	admin_noor	770004445	$2b$12$KMUsKTEtaHexhlAiX8WEyeJAykkLlHybIQNHpDJessAjDdLBhOYoi	active	2026-03-29 00:44:14.304586	2026-03-29 00:44:14.304586	0	3
\.


--
-- Name: academic_years_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.academic_years_id_seq', 4, true);


--
-- Name: assessment_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assessment_attachments_id_seq', 3, true);


--
-- Name: assessment_grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assessment_grades_id_seq', 54, true);


--
-- Name: assessment_reopen_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assessment_reopen_requests_id_seq', 2, true);


--
-- Name: assessments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assessments_id_seq', 16, true);


--
-- Name: attendance_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_entries_id_seq', 197, true);


--
-- Name: attendance_entry_corrections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_entry_corrections_id_seq', 4, true);


--
-- Name: attendance_reasons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_reasons_id_seq', 5, true);


--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_sessions_id_seq', 47, true);


--
-- Name: continuing_batch_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.continuing_batch_items_id_seq', 1, false);


--
-- Name: continuing_batches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.continuing_batches_id_seq', 1, false);


--
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_id_seq', 13, true);


--
-- Name: exam_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_entries_id_seq', 1, false);


--
-- Name: exam_schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_schedules_id_seq', 1, false);


--
-- Name: exam_timetable_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_timetable_entries_id_seq', 52, true);


--
-- Name: exam_timetables_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_timetables_id_seq', 9, true);


--
-- Name: fee_contracts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fee_contracts_id_seq', 8, true);


--
-- Name: fee_installments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fee_installments_id_seq', 128, true);


--
-- Name: fee_payment_allocations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fee_payment_allocations_id_seq', 15, true);


--
-- Name: fee_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fee_payments_id_seq', 12, true);


--
-- Name: fee_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fee_rules_id_seq', 2, true);


--
-- Name: grade_change_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grade_change_logs_id_seq', 54, true);


--
-- Name: grade_policies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grade_policies_id_seq', 1, false);


--
-- Name: grade_subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grade_subjects_id_seq', 142, true);


--
-- Name: grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grades_id_seq', 9, true);


--
-- Name: guardians_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.guardians_id_seq', 14, true);


--
-- Name: lesson_substitutions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lesson_substitutions_id_seq', 24, true);


--
-- Name: modules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modules_id_seq', 27, true);


--
-- Name: notification_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_attachments_id_seq', 1, false);


--
-- Name: notification_recipients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_recipients_id_seq', 63, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 40, true);


--
-- Name: periods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.periods_id_seq', 36, true);


--
-- Name: permission_request_recipients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permission_request_recipients_id_seq', 1, false);


--
-- Name: permission_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permission_requests_id_seq', 25, true);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permissions_id_seq', 80, true);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_permissions_id_seq', 1263, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 29, true);


--
-- Name: school_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.school_settings_id_seq', 2, true);


--
-- Name: schools_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schools_id_seq', 3, true);


--
-- Name: schools_master_registry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schools_master_registry_id_seq', 1, false);


--
-- Name: section_advisors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.section_advisors_id_seq', 1, false);


--
-- Name: section_subject_teachers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.section_subject_teachers_id_seq', 181, true);


--
-- Name: sections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sections_id_seq', 37, true);


--
-- Name: stages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stages_id_seq', 4, true);


--
-- Name: student_enrollments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_enrollments_id_seq', 49, true);


--
-- Name: student_guardians_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_guardians_id_seq', 26, true);


--
-- Name: student_year_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_year_results_id_seq', 22, true);


--
-- Name: students_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.students_id_seq', 27, true);


--
-- Name: subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subjects_id_seq', 19, true);


--
-- Name: submission_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.submission_attachments_id_seq', 1, true);


--
-- Name: submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.submissions_id_seq', 6, true);


--
-- Name: teacher_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_assignments_id_seq', 101, true);


--
-- Name: teacher_attendance_corrections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_attendance_corrections_id_seq', 13, true);


--
-- Name: teacher_attendance_days_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_attendance_days_id_seq', 4, true);


--
-- Name: teacher_attendance_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_attendance_entries_id_seq', 4, true);


--
-- Name: teacher_attendance_scan_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_attendance_scan_events_id_seq', 27, true);


--
-- Name: teacher_attendance_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_attendance_settings_id_seq', 1, false);


--
-- Name: teacher_cards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_cards_id_seq', 1, false);


--
-- Name: teacher_lesson_presence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_lesson_presence_id_seq', 1, false);


--
-- Name: teacher_permission_request_slots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_permission_request_slots_id_seq', 17, true);


--
-- Name: teacher_permission_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_permission_requests_id_seq', 17, true);


--
-- Name: teacher_subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teacher_subjects_id_seq', 188, true);


--
-- Name: teachers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teachers_id_seq', 13, true);


--
-- Name: timetable_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.timetable_entries_id_seq', 558, true);


--
-- Name: timetable_overrides_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.timetable_overrides_id_seq', 67, true);


--
-- Name: timetables_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.timetables_id_seq', 15, true);


--
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_roles_id_seq', 66, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 55, true);


--
-- Name: academic_years academic_years_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT academic_years_pkey PRIMARY KEY (id);


--
-- Name: assessment_attachments assessment_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_attachments
    ADD CONSTRAINT assessment_attachments_pkey PRIMARY KEY (id);


--
-- Name: assessment_grades assessment_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_grades
    ADD CONSTRAINT assessment_grades_pkey PRIMARY KEY (id);


--
-- Name: assessment_reopen_requests assessment_reopen_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_reopen_requests
    ADD CONSTRAINT assessment_reopen_requests_pkey PRIMARY KEY (id);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);


--
-- Name: attendance_entries attendance_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entries
    ADD CONSTRAINT attendance_entries_pkey PRIMARY KEY (id);


--
-- Name: attendance_entries attendance_entries_session_student_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entries
    ADD CONSTRAINT attendance_entries_session_student_uniq UNIQUE (session_id, student_id);


--
-- Name: attendance_entry_corrections attendance_entry_corrections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entry_corrections
    ADD CONSTRAINT attendance_entry_corrections_pkey PRIMARY KEY (id);


--
-- Name: attendance_reasons attendance_reasons_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_reasons
    ADD CONSTRAINT attendance_reasons_name_key UNIQUE (name);


--
-- Name: attendance_reasons attendance_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_reasons
    ADD CONSTRAINT attendance_reasons_pkey PRIMARY KEY (id);


--
-- Name: attendance_sessions attendance_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id);


--
-- Name: attendance_sessions attendance_sessions_unique_scope; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_unique_scope UNIQUE (academic_year_id, term, attendance_date, period_id, section_id, subject_id, teacher_id);


--
-- Name: attendance_sessions ck_attendance_sessions_term; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.attendance_sessions
    ADD CONSTRAINT ck_attendance_sessions_term CHECK ((term = ANY (ARRAY[1, 2]))) NOT VALID;


--
-- Name: exam_timetables ck_exam_timetables_scope; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.exam_timetables
    ADD CONSTRAINT ck_exam_timetables_scope CHECK (((scope)::text = ANY ((ARRAY['grade'::character varying, 'section'::character varying])::text[]))) NOT VALID;


--
-- Name: exam_timetables ck_exam_timetables_type; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.exam_timetables
    ADD CONSTRAINT ck_exam_timetables_type CHECK (((exam_type)::text = ANY ((ARRAY['monthly'::character varying, 'midyear'::character varying, 'final'::character varying])::text[]))) NOT VALID;


--
-- Name: timetable_entries ck_timetable_day_of_week; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.timetable_entries
    ADD CONSTRAINT ck_timetable_day_of_week CHECK (((day_of_week >= 1) AND (day_of_week <= 7))) NOT VALID;


--
-- Name: timetables ck_timetables_term; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.timetables
    ADD CONSTRAINT ck_timetables_term CHECK ((term = ANY (ARRAY[1, 2]))) NOT VALID;


--
-- Name: continuing_batch_items continuing_batch_items_batch_id_student_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items
    ADD CONSTRAINT continuing_batch_items_batch_id_student_id_key UNIQUE (batch_id, student_id);


--
-- Name: continuing_batch_items continuing_batch_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items
    ADD CONSTRAINT continuing_batch_items_pkey PRIMARY KEY (id);


--
-- Name: continuing_batches continuing_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batches
    ADD CONSTRAINT continuing_batches_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: employees employees_teacher_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_teacher_id_key UNIQUE (teacher_id);


--
-- Name: employees employees_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_user_id_key UNIQUE (user_id);


--
-- Name: exam_entries exam_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_entries
    ADD CONSTRAINT exam_entries_pkey PRIMARY KEY (id);


--
-- Name: exam_schedules exam_schedules_academic_year_id_stage_id_grade_id_section_i_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules
    ADD CONSTRAINT exam_schedules_academic_year_id_stage_id_grade_id_section_i_key UNIQUE (academic_year_id, stage_id, grade_id, section_id, term);


--
-- Name: exam_schedules exam_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules
    ADD CONSTRAINT exam_schedules_pkey PRIMARY KEY (id);


--
-- Name: exam_timetable_entries exam_timetable_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetable_entries
    ADD CONSTRAINT exam_timetable_entries_pkey PRIMARY KEY (id);


--
-- Name: exam_timetables exam_timetables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetables
    ADD CONSTRAINT exam_timetables_pkey PRIMARY KEY (id);


--
-- Name: fee_contracts fee_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_contracts
    ADD CONSTRAINT fee_contracts_pkey PRIMARY KEY (id);


--
-- Name: fee_installments fee_installments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_installments
    ADD CONSTRAINT fee_installments_pkey PRIMARY KEY (id);


--
-- Name: fee_payment_allocations fee_payment_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payment_allocations
    ADD CONSTRAINT fee_payment_allocations_pkey PRIMARY KEY (id);


--
-- Name: fee_payments fee_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_pkey PRIMARY KEY (id);


--
-- Name: fee_payments fee_payments_receipt_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_receipt_number_key UNIQUE (receipt_number);


--
-- Name: fee_rules fee_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_rules
    ADD CONSTRAINT fee_rules_pkey PRIMARY KEY (id);


--
-- Name: grade_change_logs grade_change_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_change_logs
    ADD CONSTRAINT grade_change_logs_pkey PRIMARY KEY (id);


--
-- Name: grade_policies grade_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_policies
    ADD CONSTRAINT grade_policies_pkey PRIMARY KEY (id);


--
-- Name: grade_subjects grade_subjects_grade_id_subject_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_subjects
    ADD CONSTRAINT grade_subjects_grade_id_subject_id_key UNIQUE (grade_id, subject_id);


--
-- Name: grade_subjects grade_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_subjects
    ADD CONSTRAINT grade_subjects_pkey PRIMARY KEY (id);


--
-- Name: grades grades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (id);


--
-- Name: grades grades_stage_id_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_stage_id_name_key UNIQUE (stage_id, name);


--
-- Name: guardians guardians_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT guardians_pkey PRIMARY KEY (id);


--
-- Name: guardians guardians_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT guardians_user_id_key UNIQUE (user_id);


--
-- Name: lesson_substitutions lesson_substitutions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson_substitutions
    ADD CONSTRAINT lesson_substitutions_pkey PRIMARY KEY (id);


--
-- Name: lesson_substitutions lesson_substitutions_substitution_date_timetable_entry_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson_substitutions
    ADD CONSTRAINT lesson_substitutions_substitution_date_timetable_entry_id_key UNIQUE (substitution_date, timetable_entry_id);


--
-- Name: modules modules_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_code_key UNIQUE (code);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (id);


--
-- Name: notification_attachments notification_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_attachments
    ADD CONSTRAINT notification_attachments_pkey PRIMARY KEY (id);


--
-- Name: notification_recipients notification_recipients_notification_id_recipient_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT notification_recipients_notification_id_recipient_user_id_key UNIQUE (notification_id, recipient_user_id);


--
-- Name: notification_recipients notification_recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT notification_recipients_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: periods periods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (id);


--
-- Name: periods periods_sort_order_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_sort_order_key UNIQUE (sort_order);


--
-- Name: permission_request_recipients permission_request_recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_request_recipients
    ADD CONSTRAINT permission_request_recipients_pkey PRIMARY KEY (id);


--
-- Name: permission_request_recipients permission_request_recipients_request_id_teacher_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_request_recipients
    ADD CONSTRAINT permission_request_recipients_request_id_teacher_id_key UNIQUE (request_id, teacher_id);


--
-- Name: permission_requests permission_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_requests
    ADD CONSTRAINT permission_requests_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_code_key UNIQUE (code);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_role_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_permission_id_key UNIQUE (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: scan_token_uses scan_token_uses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_token_uses
    ADD CONSTRAINT scan_token_uses_pkey PRIMARY KEY (jti);


--
-- Name: school_settings school_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT school_settings_pkey PRIMARY KEY (id);


--
-- Name: schools_master_registry schools_master_registry_admin_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools_master_registry
    ADD CONSTRAINT schools_master_registry_admin_email_key UNIQUE (admin_email);


--
-- Name: schools_master_registry schools_master_registry_db_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools_master_registry
    ADD CONSTRAINT schools_master_registry_db_name_key UNIQUE (db_name);


--
-- Name: schools_master_registry schools_master_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools_master_registry
    ADD CONSTRAINT schools_master_registry_pkey PRIMARY KEY (id);


--
-- Name: schools schools_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (id);


--
-- Name: section_advisors section_advisors_academic_year_id_term_section_id_role_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_advisors
    ADD CONSTRAINT section_advisors_academic_year_id_term_section_id_role_key UNIQUE (academic_year_id, term, section_id, role);


--
-- Name: section_advisors section_advisors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_advisors
    ADD CONSTRAINT section_advisors_pkey PRIMARY KEY (id);


--
-- Name: section_subject_teachers section_subject_teachers_academic_year_id_term_section_id_s_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT section_subject_teachers_academic_year_id_term_section_id_s_key UNIQUE (academic_year_id, term, section_id, subject_id);


--
-- Name: section_subject_teachers section_subject_teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT section_subject_teachers_pkey PRIMARY KEY (id);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: stages stages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stages
    ADD CONSTRAINT stages_pkey PRIMARY KEY (id);


--
-- Name: student_enrollments student_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT student_enrollments_pkey PRIMARY KEY (id);


--
-- Name: student_guardians student_guardians_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_guardians
    ADD CONSTRAINT student_guardians_pkey PRIMARY KEY (id);


--
-- Name: student_year_results student_year_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_year_results
    ADD CONSTRAINT student_year_results_pkey PRIMARY KEY (id);


--
-- Name: student_year_results student_year_results_student_id_academic_year_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_year_results
    ADD CONSTRAINT student_year_results_student_id_academic_year_id_key UNIQUE (student_id, academic_year_id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: students students_student_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_code_key UNIQUE (student_code);


--
-- Name: students students_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_key UNIQUE (user_id);


--
-- Name: subjects subjects_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_name_key UNIQUE (name);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: submission_attachments submission_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_attachments
    ADD CONSTRAINT submission_attachments_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: teacher_assignments teacher_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_assignments
    ADD CONSTRAINT teacher_assignments_pkey PRIMARY KEY (id);


--
-- Name: teacher_attendance_corrections teacher_attendance_corrections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_corrections
    ADD CONSTRAINT teacher_attendance_corrections_pkey PRIMARY KEY (id);


--
-- Name: teacher_attendance_days teacher_attendance_days_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_days
    ADD CONSTRAINT teacher_attendance_days_pkey PRIMARY KEY (id);


--
-- Name: teacher_attendance_entries teacher_attendance_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_entries
    ADD CONSTRAINT teacher_attendance_entries_pkey PRIMARY KEY (id);


--
-- Name: teacher_attendance_scan_events teacher_attendance_scan_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_scan_events
    ADD CONSTRAINT teacher_attendance_scan_events_pkey PRIMARY KEY (id);


--
-- Name: teacher_attendance_settings teacher_attendance_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_settings
    ADD CONSTRAINT teacher_attendance_settings_pkey PRIMARY KEY (id);


--
-- Name: teacher_barcode_tokens teacher_barcode_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_barcode_tokens
    ADD CONSTRAINT teacher_barcode_tokens_pkey PRIMARY KEY (teacher_id);


--
-- Name: teacher_cards teacher_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_cards
    ADD CONSTRAINT teacher_cards_pkey PRIMARY KEY (id);


--
-- Name: teacher_lesson_presence teacher_lesson_presence_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_lesson_presence
    ADD CONSTRAINT teacher_lesson_presence_pkey PRIMARY KEY (id);


--
-- Name: teacher_permission_request_slots teacher_permission_request_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_request_slots
    ADD CONSTRAINT teacher_permission_request_slots_pkey PRIMARY KEY (id);


--
-- Name: teacher_permission_requests teacher_permission_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_requests
    ADD CONSTRAINT teacher_permission_requests_pkey PRIMARY KEY (id);


--
-- Name: teacher_subjects teacher_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_subjects
    ADD CONSTRAINT teacher_subjects_pkey PRIMARY KEY (id);


--
-- Name: teacher_subjects teacher_subjects_teacher_id_subject_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_subjects
    ADD CONSTRAINT teacher_subjects_teacher_id_subject_id_key UNIQUE (teacher_id, subject_id);


--
-- Name: teachers teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_pkey PRIMARY KEY (id);


--
-- Name: teachers teachers_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_user_id_key UNIQUE (user_id);


--
-- Name: timetable_entries timetable_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT timetable_entries_pkey PRIMARY KEY (id);


--
-- Name: timetable_entries timetable_entries_timetable_id_day_of_week_period_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT timetable_entries_timetable_id_day_of_week_period_id_key UNIQUE (timetable_id, day_of_week, period_id);


--
-- Name: timetable_overrides timetable_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT timetable_overrides_pkey PRIMARY KEY (id);


--
-- Name: timetable_overrides timetable_overrides_timetable_id_date_period_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT timetable_overrides_timetable_id_date_period_id_key UNIQUE (timetable_id, date, period_id);


--
-- Name: timetable_overrides timetable_overrides_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT timetable_overrides_unique UNIQUE (timetable_id, date, period_id);


--
-- Name: timetables timetables_academic_year_id_stage_id_grade_id_section_id_te_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT timetables_academic_year_id_stage_id_grade_id_section_id_te_key UNIQUE (academic_year_id, stage_id, grade_id, section_id, term);


--
-- Name: timetables timetables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT timetables_pkey PRIMARY KEY (id);


--
-- Name: attendance_sessions uniq_attendance_session_once; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT uniq_attendance_session_once UNIQUE (teacher_id, section_id, subject_id, period_id, attendance_date);


--
-- Name: assessment_grades uq_assessment_grade; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_grades
    ADD CONSTRAINT uq_assessment_grade UNIQUE (assessment_id, student_id);


--
-- Name: attendance_sessions uq_attendance_sessions_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT uq_attendance_sessions_key UNIQUE (academic_year_id, term, attendance_date, period_id, section_id, subject_id);


--
-- Name: fee_contracts uq_contract_student_year; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_contracts
    ADD CONSTRAINT uq_contract_student_year UNIQUE (student_id, academic_year_id);


--
-- Name: exam_schedules uq_exam_schedules_year_term_stage_grade_section; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules
    ADD CONSTRAINT uq_exam_schedules_year_term_stage_grade_section UNIQUE (academic_year_id, term, stage_id, grade_id, section_id);


--
-- Name: fee_installments uq_installment_no; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_installments
    ADD CONSTRAINT uq_installment_no UNIQUE (contract_id, installment_no);


--
-- Name: school_settings uq_school_settings_school; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT uq_school_settings_school UNIQUE (school_id);


--
-- Name: schools uq_schools_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT uq_schools_code UNIQUE (code);


--
-- Name: schools uq_schools_slug; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT uq_schools_slug UNIQUE (slug);


--
-- Name: student_enrollments uq_student_enrollments_student_year_term; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT uq_student_enrollments_student_year_term UNIQUE (student_id, academic_year_id, term);


--
-- Name: student_guardians uq_student_guardian; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_guardians
    ADD CONSTRAINT uq_student_guardian UNIQUE (student_id, guardian_id);


--
-- Name: student_enrollments uq_student_year; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT uq_student_year UNIQUE (student_id, academic_year_id);


--
-- Name: submissions uq_submission; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT uq_submission UNIQUE (assessment_id, student_id);


--
-- Name: teacher_attendance_entries uq_teacher_att_entries_day_teacher; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_entries
    ADD CONSTRAINT uq_teacher_att_entries_day_teacher UNIQUE (day_id, teacher_id);


--
-- Name: teacher_attendance_days uq_teacher_attendance_days_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_days
    ADD CONSTRAINT uq_teacher_attendance_days_date UNIQUE (attendance_date);


--
-- Name: teacher_cards uq_teacher_cards_card_uid; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_cards
    ADD CONSTRAINT uq_teacher_cards_card_uid UNIQUE (card_uid);


--
-- Name: teacher_permission_request_slots uq_teacher_perm_slots_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_request_slots
    ADD CONSTRAINT uq_teacher_perm_slots_unique UNIQUE (permission_request_id, timetable_entry_id);


--
-- Name: teacher_assignments uq_teacher_scope; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_assignments
    ADD CONSTRAINT uq_teacher_scope UNIQUE (teacher_id, academic_year_id, term, section_id, subject_id);


--
-- Name: timetables uq_timetables_year_term_section; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT uq_timetables_year_term_section UNIQUE (academic_year_id, term, section_id);


--
-- Name: teacher_lesson_presence uq_tlp_date_teacher_tt; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_lesson_presence
    ADD CONSTRAINT uq_tlp_date_teacher_tt UNIQUE (presence_date, teacher_id, timetable_entry_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: attendance_entries_session_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attendance_entries_session_idx ON public.attendance_entries USING btree (session_id);


--
-- Name: attendance_sessions_unique_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX attendance_sessions_unique_idx ON public.attendance_sessions USING btree (teacher_id, academic_year_id, term, attendance_date, period_id, stage_id, grade_id, section_id, subject_id);


--
-- Name: attendance_sessions_unique_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX attendance_sessions_unique_slot ON public.attendance_sessions USING btree (teacher_id, academic_year_id, term, attendance_date, period_id, section_id);


--
-- Name: idx_academic_years_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_academic_years_school_id ON public.academic_years USING btree (school_id);


--
-- Name: idx_aec_session_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_aec_session_student ON public.attendance_entry_corrections USING btree (session_id, student_id, created_at DESC);


--
-- Name: idx_ag_assessment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ag_assessment ON public.assessment_grades USING btree (assessment_id);


--
-- Name: idx_ag_publish; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ag_publish ON public.assessment_grades USING btree (assessment_id, is_published);


--
-- Name: idx_ag_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ag_student ON public.assessment_grades USING btree (student_id);


--
-- Name: idx_ass_attach; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ass_attach ON public.assessment_attachments USING btree (assessment_id);


--
-- Name: idx_ass_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ass_dates ON public.assessments USING btree (starts_at, due_at);


--
-- Name: idx_ass_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ass_status ON public.assessments USING btree (status);


--
-- Name: idx_ass_ta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ass_ta ON public.assessments USING btree (teacher_assignment_id);


--
-- Name: idx_assessment_grades_assessment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessment_grades_assessment ON public.assessment_grades USING btree (assessment_id);


--
-- Name: idx_assessment_grades_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessment_grades_student ON public.assessment_grades USING btree (student_id);


--
-- Name: idx_assessments_aggregate_kind; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessments_aggregate_kind ON public.assessments USING btree (aggregate_kind) WHERE (aggregate_kind IS NOT NULL);


--
-- Name: idx_assessments_exam_kind; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessments_exam_kind ON public.assessments USING btree (exam_kind) WHERE (exam_kind IS NOT NULL);


--
-- Name: idx_assessments_teacher_assignment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessments_teacher_assignment ON public.assessments USING btree (teacher_assignment_id);


--
-- Name: idx_assessments_teacher_assignment_exam_kind; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessments_teacher_assignment_exam_kind ON public.assessments USING btree (teacher_assignment_id, exam_kind, sequence_no) WHERE (exam_kind IS NOT NULL);


--
-- Name: idx_assessments_teacher_assignment_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessments_teacher_assignment_type ON public.assessments USING btree (teacher_assignment_id, type);


--
-- Name: idx_assessments_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assessments_type ON public.assessments USING btree (type);


--
-- Name: idx_att_corr_session_student_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_att_corr_session_student_created ON public.attendance_entry_corrections USING btree (session_id, student_id, created_at DESC);


--
-- Name: idx_attendance_entries_session; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_entries_session ON public.attendance_entries USING btree (session_id);


--
-- Name: idx_attendance_sessions_teacher_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_sessions_teacher_date ON public.attendance_sessions USING btree (teacher_id, attendance_date);


--
-- Name: idx_employees_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_active ON public.employees USING btree (is_active);


--
-- Name: idx_employees_is_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_is_teacher ON public.employees USING btree (is_teacher);


--
-- Name: idx_employees_school_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_school_active ON public.employees USING btree (school_id, is_active);


--
-- Name: idx_employees_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_school_id ON public.employees USING btree (school_id);


--
-- Name: idx_employees_school_teacher_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_school_teacher_id ON public.employees USING btree (school_id, teacher_id);


--
-- Name: idx_employees_school_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_school_user_id ON public.employees USING btree (school_id, user_id);


--
-- Name: idx_employees_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_employees_search ON public.employees USING btree (full_name, phone);


--
-- Name: idx_entries_session; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_entries_session ON public.attendance_entries USING btree (session_id);


--
-- Name: idx_exam_entries_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_entries_date ON public.exam_entries USING btree (exam_date);


--
-- Name: idx_exam_entries_schedule; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_entries_schedule ON public.exam_entries USING btree (exam_schedule_id);


--
-- Name: idx_exam_schedules_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_schedules_lookup ON public.exam_schedules USING btree (academic_year_id, stage_id, grade_id, section_id, term);


--
-- Name: idx_fee_alloc_installment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_alloc_installment ON public.fee_payment_allocations USING btree (installment_id);


--
-- Name: idx_fee_alloc_payment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_alloc_payment ON public.fee_payment_allocations USING btree (payment_id);


--
-- Name: idx_fee_contracts_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_contracts_student ON public.fee_contracts USING btree (student_id);


--
-- Name: idx_fee_contracts_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_contracts_year ON public.fee_contracts USING btree (academic_year_id);


--
-- Name: idx_fee_installments_contract; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_installments_contract ON public.fee_installments USING btree (contract_id);


--
-- Name: idx_fee_installments_due; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_installments_due ON public.fee_installments USING btree (due_date);


--
-- Name: idx_fee_payments_contract; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_payments_contract ON public.fee_payments USING btree (contract_id);


--
-- Name: idx_fee_payments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_payments_status ON public.fee_payments USING btree (status);


--
-- Name: idx_fee_payments_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fee_payments_student ON public.fee_payments USING btree (student_id);


--
-- Name: idx_gcl_changed_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gcl_changed_by ON public.grade_change_logs USING btree (changed_by);


--
-- Name: idx_gcl_grade; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gcl_grade ON public.grade_change_logs USING btree (grade_id);


--
-- Name: idx_grade_subjects_grade; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_subjects_grade ON public.grade_subjects USING btree (grade_id);


--
-- Name: idx_grade_subjects_school_grade; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_subjects_school_grade ON public.grade_subjects USING btree (school_id, grade_id);


--
-- Name: idx_grade_subjects_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_subjects_school_id ON public.grade_subjects USING btree (school_id);


--
-- Name: idx_grade_subjects_school_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_subjects_school_subject ON public.grade_subjects USING btree (school_id, subject_id);


--
-- Name: idx_grade_subjects_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grade_subjects_subject ON public.grade_subjects USING btree (subject_id);


--
-- Name: idx_grades_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_is_active ON public.grades USING btree (is_active);


--
-- Name: idx_grades_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_school_id ON public.grades USING btree (school_id);


--
-- Name: idx_grades_school_stage_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_school_stage_id ON public.grades USING btree (school_id, stage_id);


--
-- Name: idx_grades_stage_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_stage_id ON public.grades USING btree (stage_id);


--
-- Name: idx_guardians_school_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_guardians_school_email ON public.guardians USING btree (school_id, email);


--
-- Name: idx_guardians_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_guardians_school_id ON public.guardians USING btree (school_id);


--
-- Name: idx_guardians_school_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_guardians_school_phone ON public.guardians USING btree (school_id, phone);


--
-- Name: idx_guardians_school_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_guardians_school_user_id ON public.guardians USING btree (school_id, user_id);


--
-- Name: idx_notif_attach_nid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notif_attach_nid ON public.notification_attachments USING btree (notification_id);


--
-- Name: idx_notif_recipient_nid_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notif_recipient_nid_uid ON public.notification_recipients USING btree (notification_id, recipient_user_id);


--
-- Name: idx_notification_recipients_user_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notification_recipients_user_created ON public.notification_recipients USING btree (recipient_user_id, created_at DESC);


--
-- Name: idx_notification_recipients_user_is_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notification_recipients_user_is_read ON public.notification_recipients USING btree (recipient_user_id, is_read);


--
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at DESC);


--
-- Name: idx_periods_sort; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_periods_sort ON public.periods USING btree (sort_order);


--
-- Name: idx_perm_rec_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_perm_rec_teacher ON public.permission_request_recipients USING btree (teacher_id, created_at DESC);


--
-- Name: idx_policy; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_policy ON public.grade_policies USING btree (academic_year_id, term, subject_id);


--
-- Name: idx_sections_school_grade_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sections_school_grade_name ON public.sections USING btree (school_id, grade_id, name);


--
-- Name: idx_sessions_teacher_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_teacher_date ON public.attendance_sessions USING btree (teacher_id, attendance_date);


--
-- Name: idx_sst_school_academic_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sst_school_academic_year ON public.section_subject_teachers USING btree (school_id, academic_year_id);


--
-- Name: idx_sst_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sst_school_id ON public.section_subject_teachers USING btree (school_id);


--
-- Name: idx_sst_school_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sst_school_section ON public.section_subject_teachers USING btree (school_id, section_id);


--
-- Name: idx_sst_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sst_section ON public.section_subject_teachers USING btree (section_id);


--
-- Name: idx_sst_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sst_teacher ON public.section_subject_teachers USING btree (teacher_id);


--
-- Name: idx_sst_year_term; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sst_year_term ON public.section_subject_teachers USING btree (academic_year_id, term);


--
-- Name: idx_stages_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stages_school_id ON public.stages USING btree (school_id);


--
-- Name: idx_student_enrollments_school_grade; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_enrollments_school_grade ON public.student_enrollments USING btree (school_id, grade_id);


--
-- Name: idx_student_enrollments_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_enrollments_school_id ON public.student_enrollments USING btree (school_id);


--
-- Name: idx_student_enrollments_school_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_enrollments_school_section ON public.student_enrollments USING btree (school_id, section_id);


--
-- Name: idx_student_enrollments_school_stage; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_enrollments_school_stage ON public.student_enrollments USING btree (school_id, stage_id);


--
-- Name: idx_student_enrollments_school_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_enrollments_school_student ON public.student_enrollments USING btree (school_id, student_id);


--
-- Name: idx_student_enrollments_school_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_enrollments_school_year ON public.student_enrollments USING btree (school_id, academic_year_id);


--
-- Name: idx_student_enrollments_student_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_enrollments_student_year ON public.student_enrollments USING btree (student_id, academic_year_id);


--
-- Name: idx_student_guardians_school_guardian; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_guardians_school_guardian ON public.student_guardians USING btree (school_id, guardian_id);


--
-- Name: idx_student_guardians_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_guardians_school_id ON public.student_guardians USING btree (school_id);


--
-- Name: idx_student_guardians_school_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_guardians_school_student ON public.student_guardians USING btree (school_id, student_id);


--
-- Name: idx_student_year_results_result; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_year_results_result ON public.student_year_results USING btree (result);


--
-- Name: idx_student_year_results_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_year_results_student ON public.student_year_results USING btree (student_id);


--
-- Name: idx_student_year_results_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_year_results_year ON public.student_year_results USING btree (academic_year_id);


--
-- Name: idx_students_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_school_id ON public.students USING btree (school_id);


--
-- Name: idx_students_school_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_school_user_id ON public.students USING btree (school_id, user_id);


--
-- Name: idx_sub_assessment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sub_assessment ON public.submissions USING btree (assessment_id);


--
-- Name: idx_sub_attach; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sub_attach ON public.submission_attachments USING btree (submission_id);


--
-- Name: idx_sub_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sub_student ON public.submissions USING btree (student_id);


--
-- Name: idx_subjects_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subjects_school_id ON public.subjects USING btree (school_id);


--
-- Name: idx_submissions_assessment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_submissions_assessment ON public.submissions USING btree (assessment_id);


--
-- Name: idx_submissions_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_submissions_student ON public.submissions USING btree (student_id);


--
-- Name: idx_ta_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ta_scope ON public.teacher_assignments USING btree (academic_year_id, term, section_id, subject_id);


--
-- Name: idx_ta_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ta_teacher ON public.teacher_assignments USING btree (teacher_id);


--
-- Name: idx_te_room_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_te_room_slot ON public.timetable_entries USING btree (lower((COALESCE(room, ''::character varying))::text), day_of_week, period_id);


--
-- Name: idx_te_teacher_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_te_teacher_slot ON public.timetable_entries USING btree (teacher_id, day_of_week, period_id);


--
-- Name: idx_te_timetable; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_te_timetable ON public.timetable_entries USING btree (timetable_id);


--
-- Name: idx_teacher_att_corr_day_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_corr_day_teacher ON public.teacher_attendance_corrections USING btree (day_id, teacher_id);


--
-- Name: idx_teacher_att_corr_entry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_corr_entry ON public.teacher_attendance_corrections USING btree (entry_id);


--
-- Name: idx_teacher_att_entries_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_entries_day ON public.teacher_attendance_entries USING btree (day_id);


--
-- Name: idx_teacher_att_entries_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_entries_status ON public.teacher_attendance_entries USING btree (status);


--
-- Name: idx_teacher_att_entries_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_entries_teacher ON public.teacher_attendance_entries USING btree (teacher_id);


--
-- Name: idx_teacher_att_scan_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_scan_created_at ON public.teacher_attendance_scan_events USING btree (created_at DESC);


--
-- Name: idx_teacher_att_scan_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_scan_day ON public.teacher_attendance_scan_events USING btree (day_id);


--
-- Name: idx_teacher_att_scan_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_att_scan_teacher ON public.teacher_attendance_scan_events USING btree (teacher_id);


--
-- Name: idx_teacher_attendance_days_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_attendance_days_date ON public.teacher_attendance_days USING btree (attendance_date);


--
-- Name: idx_teacher_barcode_tokens_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_barcode_tokens_expires ON public.teacher_barcode_tokens USING btree (expires_at);


--
-- Name: idx_teacher_barcode_tokens_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_barcode_tokens_hash ON public.teacher_barcode_tokens USING btree (token_hash);


--
-- Name: idx_teacher_cards_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_cards_active ON public.teacher_cards USING btree (is_active);


--
-- Name: idx_teacher_cards_teacher_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_cards_teacher_id ON public.teacher_cards USING btree (teacher_id);


--
-- Name: idx_teacher_perm_slots_req; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_perm_slots_req ON public.teacher_permission_request_slots USING btree (permission_request_id);


--
-- Name: idx_teacher_perm_slots_tt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_perm_slots_tt ON public.teacher_permission_request_slots USING btree (timetable_entry_id);


--
-- Name: idx_teacher_perm_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_perm_status ON public.teacher_permission_requests USING btree (status);


--
-- Name: idx_teacher_perm_teacher_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_perm_teacher_date ON public.teacher_permission_requests USING btree (teacher_id, request_date DESC);


--
-- Name: idx_teacher_subjects_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_subjects_school_id ON public.teacher_subjects USING btree (school_id);


--
-- Name: idx_teacher_subjects_school_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_subjects_school_subject ON public.teacher_subjects USING btree (school_id, subject_id);


--
-- Name: idx_teacher_subjects_school_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_subjects_school_teacher ON public.teacher_subjects USING btree (school_id, teacher_id);


--
-- Name: idx_teacher_subjects_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_subjects_subject ON public.teacher_subjects USING btree (subject_id);


--
-- Name: idx_teacher_subjects_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teacher_subjects_teacher ON public.teacher_subjects USING btree (teacher_id);


--
-- Name: idx_teachers_school_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teachers_school_active ON public.teachers USING btree (school_id, is_active);


--
-- Name: idx_teachers_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teachers_school_id ON public.teachers USING btree (school_id);


--
-- Name: idx_teachers_school_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teachers_school_user_id ON public.teachers USING btree (school_id, user_id);


--
-- Name: idx_timetable_entries_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_entries_school_id ON public.timetable_entries USING btree (school_id);


--
-- Name: idx_timetable_entries_school_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_entries_school_period ON public.timetable_entries USING btree (school_id, period_id);


--
-- Name: idx_timetable_entries_school_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_entries_school_subject ON public.timetable_entries USING btree (school_id, subject_id);


--
-- Name: idx_timetable_entries_school_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_entries_school_teacher ON public.timetable_entries USING btree (school_id, teacher_id);


--
-- Name: idx_timetable_entries_school_timetable; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_entries_school_timetable ON public.timetable_entries USING btree (school_id, timetable_id);


--
-- Name: idx_timetable_entries_timetable; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_entries_timetable ON public.timetable_entries USING btree (timetable_id);


--
-- Name: idx_timetable_overrides_school_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_overrides_school_date ON public.timetable_overrides USING btree (school_id, date);


--
-- Name: idx_timetable_overrides_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_overrides_school_id ON public.timetable_overrides USING btree (school_id);


--
-- Name: idx_timetable_overrides_school_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_overrides_school_period ON public.timetable_overrides USING btree (school_id, period_id);


--
-- Name: idx_timetable_overrides_school_timetable; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetable_overrides_school_timetable ON public.timetable_overrides USING btree (school_id, timetable_id);


--
-- Name: idx_timetables_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetables_lookup ON public.timetables USING btree (academic_year_id, stage_id, grade_id, section_id, term);


--
-- Name: idx_timetables_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetables_school_id ON public.timetables USING btree (school_id);


--
-- Name: idx_timetables_school_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetables_school_section ON public.timetables USING btree (school_id, section_id);


--
-- Name: idx_timetables_school_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_timetables_school_year ON public.timetables USING btree (school_id, academic_year_id);


--
-- Name: idx_tlp_att_session; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tlp_att_session ON public.teacher_lesson_presence USING btree (attendance_session_id);


--
-- Name: idx_tlp_date_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tlp_date_teacher ON public.teacher_lesson_presence USING btree (presence_date, teacher_id);


--
-- Name: idx_tlp_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tlp_status ON public.teacher_lesson_presence USING btree (status);


--
-- Name: idx_tt_year_term_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tt_year_term_status ON public.timetables USING btree (academic_year_id, term, status);


--
-- Name: idx_tto_tt_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tto_tt_date ON public.timetable_overrides USING btree (timetable_id, date);


--
-- Name: idx_tto_tt_date_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tto_tt_date_status ON public.timetable_overrides USING btree (timetable_id, date, status);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_users_school_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_school_id ON public.users USING btree (school_id);


--
-- Name: ix_att_entries_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_att_entries_status ON public.attendance_entries USING btree (status);


--
-- Name: ix_att_entries_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_att_entries_student ON public.attendance_entries USING btree (student_id);


--
-- Name: ix_att_entries_student_session; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_att_entries_student_session ON public.attendance_entries USING btree (student_id, session_id);


--
-- Name: ix_att_sessions_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_att_sessions_date ON public.attendance_sessions USING btree (attendance_date);


--
-- Name: ix_att_sessions_section_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_att_sessions_section_date ON public.attendance_sessions USING btree (section_id, attendance_date);


--
-- Name: ix_exam_entries_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_exam_entries_date ON public.exam_timetable_entries USING btree (exam_date);


--
-- Name: ix_exam_entries_tt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_exam_entries_tt ON public.exam_timetable_entries USING btree (exam_timetable_id);


--
-- Name: ix_permission_by_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_permission_by_date ON public.permission_requests USING btree (request_date);


--
-- Name: ix_permission_by_parent_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_permission_by_parent_date ON public.permission_requests USING btree (parent_user_id, request_date);


--
-- Name: ix_permission_by_status_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_permission_by_status_date ON public.permission_requests USING btree (status, request_date);


--
-- Name: ix_student_enrollments_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_enrollments_scope ON public.student_enrollments USING btree (academic_year_id, term, stage_id, grade_id, section_id, student_id);


--
-- Name: scan_token_uses_session_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX scan_token_uses_session_idx ON public.scan_token_uses USING btree (session_id);


--
-- Name: scan_token_uses_student_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX scan_token_uses_student_idx ON public.scan_token_uses USING btree (student_id);


--
-- Name: uniq_attendance_entry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uniq_attendance_entry ON public.attendance_entries USING btree (session_id, student_id);


--
-- Name: uniq_attendance_entry_once; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uniq_attendance_entry_once ON public.attendance_entries USING btree (session_id, student_id);


--
-- Name: uniq_attendance_session_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uniq_attendance_session_scope ON public.attendance_sessions USING btree (teacher_id, academic_year_id, term, attendance_date, period_id, section_id);


--
-- Name: uq_academic_years_one_active_per_school; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_academic_years_one_active_per_school ON public.academic_years USING btree (school_id) WHERE (is_active = true);


--
-- Name: uq_academic_years_school_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_academic_years_school_name ON public.academic_years USING btree (school_id, name);


--
-- Name: uq_assessment_grades_assessment_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_assessment_grades_assessment_student ON public.assessment_grades USING btree (assessment_id, student_id);


--
-- Name: uq_assessments_aggregate_kind; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_assessments_aggregate_kind ON public.assessments USING btree (teacher_assignment_id, aggregate_kind) WHERE ((type)::text = 'aggregate'::text);


--
-- Name: uq_assessments_midterm_final_exam; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_assessments_midterm_final_exam ON public.assessments USING btree (teacher_assignment_id, exam_kind) WHERE (((type)::text = 'exam'::text) AND ((exam_kind)::text = ANY ((ARRAY['midterm'::character varying, 'final'::character varying])::text[])));


--
-- Name: uq_assessments_monthly_exam; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_assessments_monthly_exam ON public.assessments USING btree (teacher_assignment_id, exam_kind, sequence_no) WHERE (((type)::text = 'exam'::text) AND ((exam_kind)::text = 'monthly'::text));


--
-- Name: uq_grade_policies_scope_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_grade_policies_scope_active ON public.grade_policies USING btree (academic_year_id, term, subject_id, COALESCE((stage_id)::integer, 0), COALESCE((grade_id)::integer, 0)) WHERE (is_active = true);


--
-- Name: uq_grade_subjects_school_grade_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_grade_subjects_school_grade_subject ON public.grade_subjects USING btree (school_id, grade_id, subject_id);


--
-- Name: uq_grades_school_stage_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_grades_school_stage_name ON public.grades USING btree (school_id, stage_id, name);


--
-- Name: uq_grades_school_stage_order_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_grades_school_stage_order_index ON public.grades USING btree (school_id, stage_id, order_index);


--
-- Name: uq_notification_recipients_notification_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_notification_recipients_notification_user ON public.notification_recipients USING btree (notification_id, recipient_user_id);


--
-- Name: uq_permission_one_per_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_permission_one_per_day ON public.permission_requests USING btree (student_id, request_date);


--
-- Name: uq_sections_school_grade_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_sections_school_grade_name ON public.sections USING btree (school_id, grade_id, name);


--
-- Name: uq_sst_school_year_term_section_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_sst_school_year_term_section_subject ON public.section_subject_teachers USING btree (school_id, academic_year_id, term, section_id, subject_id);


--
-- Name: uq_stages_school_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_stages_school_name ON public.stages USING btree (school_id, name);


--
-- Name: uq_stages_school_order_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_stages_school_order_index ON public.stages USING btree (school_id, order_index);


--
-- Name: uq_student_guardians_school_student_guardian; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_student_guardians_school_student_guardian ON public.student_guardians USING btree (school_id, student_id, guardian_id);


--
-- Name: uq_students_school_student_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_students_school_student_code ON public.students USING btree (school_id, student_code);


--
-- Name: uq_subjects_school_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_subjects_school_name ON public.subjects USING btree (school_id, name);


--
-- Name: uq_teacher_full_day_approved_once; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_teacher_full_day_approved_once ON public.teacher_permission_requests USING btree (teacher_id, request_date) WHERE ((status = 'approved'::text) AND (scope = 'full_day'::text));


--
-- Name: uq_teacher_one_active_card; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_teacher_one_active_card ON public.teacher_cards USING btree (teacher_id) WHERE (is_active = true);


--
-- Name: uq_teacher_perm_pending_once; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_teacher_perm_pending_once ON public.teacher_permission_requests USING btree (teacher_id, request_date) WHERE (status = 'pending'::text);


--
-- Name: uq_teacher_subjects_school_teacher_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_teacher_subjects_school_teacher_subject ON public.teacher_subjects USING btree (school_id, teacher_id, subject_id);


--
-- Name: uq_timetable_entries_school_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_timetable_entries_school_slot ON public.timetable_entries USING btree (school_id, timetable_id, day_of_week, period_id);


--
-- Name: uq_timetable_entries_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_timetable_entries_slot ON public.timetable_entries USING btree (timetable_id, day_of_week, period_id);


--
-- Name: uq_timetable_overrides_school_date_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_timetable_overrides_school_date_slot ON public.timetable_overrides USING btree (school_id, timetable_id, date, period_id);


--
-- Name: uq_timetables_school_year_term_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_timetables_school_year_term_section ON public.timetables USING btree (school_id, academic_year_id, term, section_id);


--
-- Name: uq_users_school_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_users_school_email ON public.users USING btree (school_id, email) WHERE (email IS NOT NULL);


--
-- Name: uq_users_school_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_users_school_username ON public.users USING btree (school_id, username) WHERE (username IS NOT NULL);


--
-- Name: ux_att_entries_session_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_att_entries_session_student ON public.attendance_entries USING btree (session_id, student_id);


--
-- Name: ux_att_sessions_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_att_sessions_unique ON public.attendance_sessions USING btree (academic_year_id, term, attendance_date, period_id, section_id, subject_id);


--
-- Name: ux_attendance_entries_session_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_attendance_entries_session_student ON public.attendance_entries USING btree (session_id, student_id);


--
-- Name: ux_attendance_sessions_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_attendance_sessions_unique ON public.attendance_sessions USING btree (academic_year_id, term, attendance_date, period_id, section_id, subject_id, teacher_id);


--
-- Name: ux_exam_entry_slot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_exam_entry_slot ON public.exam_timetable_entries USING btree (exam_timetable_id, exam_date, start_time, end_time, COALESCE(apply_to_section_id, 0));


--
-- Name: ux_exam_tt_grade; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_exam_tt_grade ON public.exam_timetables USING btree (academic_year_id, stage_id, grade_id, exam_type, month, scope) WHERE ((scope)::text = 'grade'::text);


--
-- Name: ux_exam_tt_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_exam_tt_section ON public.exam_timetables USING btree (academic_year_id, stage_id, grade_id, section_id, exam_type, month, scope) WHERE ((scope)::text = 'section'::text);


--
-- Name: ux_fee_rules_default; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_fee_rules_default ON public.fee_rules USING btree (academic_year_id, scope) WHERE (scope = 'DEFAULT'::text);


--
-- Name: ux_fee_rules_grade; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_fee_rules_grade ON public.fee_rules USING btree (academic_year_id, scope, grade_id) WHERE (scope = 'GRADE'::text);


--
-- Name: ux_fee_rules_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_fee_rules_section ON public.fee_rules USING btree (academic_year_id, scope, section_id) WHERE (scope = 'SECTION'::text);


--
-- Name: ux_fee_rules_stage; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_fee_rules_stage ON public.fee_rules USING btree (academic_year_id, scope, stage_id) WHERE (scope = 'STAGE'::text);


--
-- Name: ux_fee_rules_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_fee_rules_student ON public.fee_rules USING btree (academic_year_id, scope, student_id) WHERE (scope = 'STUDENT'::text);


--
-- Name: ux_student_year_results_year_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_student_year_results_year_student ON public.student_year_results USING btree (academic_year_id, student_id);


--
-- Name: assessment_grades trg_assessment_grades_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_assessment_grades_updated BEFORE UPDATE ON public.assessment_grades FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: assessments trg_assessments_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_assessments_updated BEFORE UPDATE ON public.assessments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: attendance_entries trg_prevent_edit_on_locked_session; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_edit_on_locked_session BEFORE INSERT OR UPDATE ON public.attendance_entries FOR EACH ROW EXECUTE FUNCTION public.prevent_edit_on_locked_session();


--
-- Name: submissions trg_submissions_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_submissions_updated BEFORE UPDATE ON public.submissions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: assessment_reopen_requests assessment_reopen_requests_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_reopen_requests
    ADD CONSTRAINT assessment_reopen_requests_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: assessment_reopen_requests assessment_reopen_requests_decided_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_reopen_requests
    ADD CONSTRAINT assessment_reopen_requests_decided_by_user_id_fkey FOREIGN KEY (decided_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: assessment_reopen_requests assessment_reopen_requests_requested_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_reopen_requests
    ADD CONSTRAINT assessment_reopen_requests_requested_by_user_id_fkey FOREIGN KEY (requested_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: attendance_entries attendance_entries_reason_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entries
    ADD CONSTRAINT attendance_entries_reason_id_fkey FOREIGN KEY (reason_id) REFERENCES public.attendance_reasons(id) ON DELETE SET NULL;


--
-- Name: attendance_entries attendance_entries_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entries
    ADD CONSTRAINT attendance_entries_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.attendance_sessions(id) ON DELETE CASCADE;


--
-- Name: attendance_entries attendance_entries_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entries
    ADD CONSTRAINT attendance_entries_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE RESTRICT;


--
-- Name: attendance_entry_corrections attendance_entry_corrections_permission_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entry_corrections
    ADD CONSTRAINT attendance_entry_corrections_permission_request_id_fkey FOREIGN KEY (permission_request_id) REFERENCES public.permission_requests(id);


--
-- Name: attendance_entry_corrections attendance_entry_corrections_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entry_corrections
    ADD CONSTRAINT attendance_entry_corrections_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.attendance_sessions(id) ON DELETE CASCADE;


--
-- Name: attendance_entry_corrections attendance_entry_corrections_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entry_corrections
    ADD CONSTRAINT attendance_entry_corrections_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: attendance_sessions attendance_sessions_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE RESTRICT;


--
-- Name: attendance_sessions attendance_sessions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: attendance_sessions attendance_sessions_locked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_locked_by_fkey FOREIGN KEY (locked_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: attendance_sessions attendance_sessions_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id) ON DELETE RESTRICT;


--
-- Name: attendance_sessions attendance_sessions_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE RESTRICT;


--
-- Name: attendance_sessions attendance_sessions_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- Name: attendance_sessions attendance_sessions_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE RESTRICT;


--
-- Name: continuing_batch_items continuing_batch_items_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items
    ADD CONSTRAINT continuing_batch_items_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.continuing_batches(id) ON DELETE CASCADE;


--
-- Name: continuing_batch_items continuing_batch_items_from_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items
    ADD CONSTRAINT continuing_batch_items_from_enrollment_id_fkey FOREIGN KEY (from_enrollment_id) REFERENCES public.student_enrollments(id);


--
-- Name: continuing_batch_items continuing_batch_items_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items
    ADD CONSTRAINT continuing_batch_items_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: continuing_batch_items continuing_batch_items_to_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items
    ADD CONSTRAINT continuing_batch_items_to_enrollment_id_fkey FOREIGN KEY (to_enrollment_id) REFERENCES public.student_enrollments(id);


--
-- Name: continuing_batch_items continuing_batch_items_to_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batch_items
    ADD CONSTRAINT continuing_batch_items_to_section_id_fkey FOREIGN KEY (to_section_id) REFERENCES public.sections(id);


--
-- Name: continuing_batches continuing_batches_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batches
    ADD CONSTRAINT continuing_batches_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: continuing_batches continuing_batches_default_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batches
    ADD CONSTRAINT continuing_batches_default_section_id_fkey FOREIGN KEY (default_section_id) REFERENCES public.sections(id);


--
-- Name: continuing_batches continuing_batches_from_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batches
    ADD CONSTRAINT continuing_batches_from_year_id_fkey FOREIGN KEY (from_year_id) REFERENCES public.academic_years(id);


--
-- Name: continuing_batches continuing_batches_to_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.continuing_batches
    ADD CONSTRAINT continuing_batches_to_year_id_fkey FOREIGN KEY (to_year_id) REFERENCES public.academic_years(id);


--
-- Name: exam_entries exam_entries_exam_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_entries
    ADD CONSTRAINT exam_entries_exam_schedule_id_fkey FOREIGN KEY (exam_schedule_id) REFERENCES public.exam_schedules(id) ON DELETE CASCADE;


--
-- Name: exam_entries exam_entries_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_entries
    ADD CONSTRAINT exam_entries_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- Name: exam_entries exam_entries_supervisor_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_entries
    ADD CONSTRAINT exam_entries_supervisor_teacher_id_fkey FOREIGN KEY (supervisor_teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: exam_schedules exam_schedules_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules
    ADD CONSTRAINT exam_schedules_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE RESTRICT;


--
-- Name: exam_schedules exam_schedules_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules
    ADD CONSTRAINT exam_schedules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: exam_schedules exam_schedules_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules
    ADD CONSTRAINT exam_schedules_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE RESTRICT;


--
-- Name: exam_schedules exam_schedules_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_schedules
    ADD CONSTRAINT exam_schedules_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.stages(id) ON DELETE RESTRICT;


--
-- Name: exam_timetable_entries exam_timetable_entries_apply_to_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetable_entries
    ADD CONSTRAINT exam_timetable_entries_apply_to_section_id_fkey FOREIGN KEY (apply_to_section_id) REFERENCES public.sections(id);


--
-- Name: exam_timetable_entries exam_timetable_entries_exam_timetable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetable_entries
    ADD CONSTRAINT exam_timetable_entries_exam_timetable_id_fkey FOREIGN KEY (exam_timetable_id) REFERENCES public.exam_timetables(id) ON DELETE CASCADE;


--
-- Name: exam_timetable_entries exam_timetable_entries_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetable_entries
    ADD CONSTRAINT exam_timetable_entries_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);


--
-- Name: exam_timetables exam_timetables_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetables
    ADD CONSTRAINT exam_timetables_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id);


--
-- Name: exam_timetables exam_timetables_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetables
    ADD CONSTRAINT exam_timetables_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- Name: exam_timetables exam_timetables_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetables
    ADD CONSTRAINT exam_timetables_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.stages(id);


--
-- Name: fee_installments fee_installments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_installments
    ADD CONSTRAINT fee_installments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.fee_contracts(id) ON DELETE CASCADE;


--
-- Name: fee_payment_allocations fee_payment_allocations_installment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payment_allocations
    ADD CONSTRAINT fee_payment_allocations_installment_id_fkey FOREIGN KEY (installment_id) REFERENCES public.fee_installments(id) ON DELETE CASCADE;


--
-- Name: fee_payment_allocations fee_payment_allocations_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payment_allocations
    ADD CONSTRAINT fee_payment_allocations_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.fee_payments(id) ON DELETE CASCADE;


--
-- Name: fee_payments fee_payments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_payments
    ADD CONSTRAINT fee_payments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.fee_contracts(id) ON DELETE CASCADE;


--
-- Name: fee_rules fee_rules_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_rules
    ADD CONSTRAINT fee_rules_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id);


--
-- Name: fee_rules fee_rules_grade_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_rules
    ADD CONSTRAINT fee_rules_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(id);


--
-- Name: fee_rules fee_rules_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_rules
    ADD CONSTRAINT fee_rules_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- Name: fee_rules fee_rules_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_rules
    ADD CONSTRAINT fee_rules_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.stages(id);


--
-- Name: fee_rules fee_rules_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fee_rules
    ADD CONSTRAINT fee_rules_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: academic_years fk_academic_years_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.academic_years
    ADD CONSTRAINT fk_academic_years_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: assessment_grades fk_ag_ass; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_grades
    ADD CONSTRAINT fk_ag_ass FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: assessment_attachments fk_ass_attach; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_attachments
    ADD CONSTRAINT fk_ass_attach FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: assessments fk_ass_ta; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT fk_ass_ta FOREIGN KEY (teacher_assignment_id) REFERENCES public.teacher_assignments(id) ON DELETE CASCADE;


--
-- Name: assessment_grades fk_assessment_grades_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessment_grades
    ADD CONSTRAINT fk_assessment_grades_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: attendance_entry_corrections fk_att_corr_reason; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entry_corrections
    ADD CONSTRAINT fk_att_corr_reason FOREIGN KEY (corrected_reason_id) REFERENCES public.attendance_reasons(id);


--
-- Name: attendance_entry_corrections fk_att_corr_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_entry_corrections
    ADD CONSTRAINT fk_att_corr_user FOREIGN KEY (corrected_by_user_id) REFERENCES public.users(id);


--
-- Name: attendance_sessions fk_attendance_sessions_stage; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT fk_attendance_sessions_stage FOREIGN KEY (stage_id) REFERENCES public.stages(id) NOT VALID;


--
-- Name: employees fk_employees_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_employees_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: employees fk_employees_teacher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_employees_teacher FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- Name: employees fk_employees_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_employees_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: student_enrollments fk_enroll_section; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT fk_enroll_section FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- Name: student_enrollments fk_enroll_stage; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT fk_enroll_stage FOREIGN KEY (stage_id) REFERENCES public.stages(id);


--
-- Name: student_enrollments fk_enroll_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_enrollments fk_enroll_year; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT fk_enroll_year FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id);


--
-- Name: exam_timetables fk_exam_timetables_created_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_timetables
    ADD CONSTRAINT fk_exam_timetables_created_by FOREIGN KEY (created_by) REFERENCES public.users(id) NOT VALID;


--
-- Name: grade_change_logs fk_gcl_grade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_change_logs
    ADD CONSTRAINT fk_gcl_grade FOREIGN KEY (grade_id) REFERENCES public.assessment_grades(id) ON DELETE CASCADE;


--
-- Name: grade_subjects fk_grade_subjects_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_subjects
    ADD CONSTRAINT fk_grade_subjects_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: grades fk_grades_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT fk_grades_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: grades fk_grades_stage; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT fk_grades_stage FOREIGN KEY (stage_id) REFERENCES public.stages(id) ON DELETE RESTRICT;


--
-- Name: guardians fk_guardians_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT fk_guardians_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: guardians fk_guardians_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT fk_guardians_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: permissions fk_permissions_module; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT fk_permissions_module FOREIGN KEY (module_id) REFERENCES public.modules(id) ON DELETE CASCADE;


--
-- Name: school_settings fk_school_settings_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT fk_school_settings_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE CASCADE;


--
-- Name: section_subject_teachers fk_section_subject_teachers_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT fk_section_subject_teachers_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: sections fk_sections_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT fk_sections_school FOREIGN KEY (school_id) REFERENCES public.schools(id);


--
-- Name: student_guardians fk_sg_guardian; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_guardians
    ADD CONSTRAINT fk_sg_guardian FOREIGN KEY (guardian_id) REFERENCES public.guardians(id) ON DELETE CASCADE;


--
-- Name: student_guardians fk_sg_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_guardians
    ADD CONSTRAINT fk_sg_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: stages fk_stages_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stages
    ADD CONSTRAINT fk_stages_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: student_enrollments fk_student_enrollments_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_enrollments
    ADD CONSTRAINT fk_student_enrollments_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: student_guardians fk_student_guardians_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_guardians
    ADD CONSTRAINT fk_student_guardians_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: student_year_results fk_student_year_results_decided_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_year_results
    ADD CONSTRAINT fk_student_year_results_decided_by FOREIGN KEY (decided_by) REFERENCES public.users(id) NOT VALID;


--
-- Name: students fk_students_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: students fk_students_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: submissions fk_sub_assessment; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_sub_assessment FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: submission_attachments fk_sub_attach; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_attachments
    ADD CONSTRAINT fk_sub_attach FOREIGN KEY (submission_id) REFERENCES public.submissions(id) ON DELETE CASCADE;


--
-- Name: subjects fk_subjects_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT fk_subjects_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: submissions fk_submissions_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_submissions_student FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: teacher_attendance_corrections fk_teacher_att_corr_day; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_corrections
    ADD CONSTRAINT fk_teacher_att_corr_day FOREIGN KEY (day_id) REFERENCES public.teacher_attendance_days(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_attendance_corrections fk_teacher_att_corr_entry; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_corrections
    ADD CONSTRAINT fk_teacher_att_corr_entry FOREIGN KEY (entry_id) REFERENCES public.teacher_attendance_entries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_attendance_corrections fk_teacher_att_corr_teacher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_corrections
    ADD CONSTRAINT fk_teacher_att_corr_teacher FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_attendance_corrections fk_teacher_att_corr_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_corrections
    ADD CONSTRAINT fk_teacher_att_corr_user FOREIGN KEY (corrected_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: teacher_attendance_days fk_teacher_att_days_created_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_days
    ADD CONSTRAINT fk_teacher_att_days_created_by FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_days fk_teacher_att_days_locked_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_days
    ADD CONSTRAINT fk_teacher_att_days_locked_by FOREIGN KEY (locked_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_days fk_teacher_att_days_year; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_days
    ADD CONSTRAINT fk_teacher_att_days_year FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_entries fk_teacher_att_entries_day; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_entries
    ADD CONSTRAINT fk_teacher_att_entries_day FOREIGN KEY (day_id) REFERENCES public.teacher_attendance_days(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_attendance_entries fk_teacher_att_entries_recorded_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_entries
    ADD CONSTRAINT fk_teacher_att_entries_recorded_by FOREIGN KEY (recorded_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_entries fk_teacher_att_entries_scanned_card; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_entries
    ADD CONSTRAINT fk_teacher_att_entries_scanned_card FOREIGN KEY (scanned_card_id) REFERENCES public.teacher_cards(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_entries fk_teacher_att_entries_teacher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_entries
    ADD CONSTRAINT fk_teacher_att_entries_teacher FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_attendance_scan_events fk_teacher_att_scan_card; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_scan_events
    ADD CONSTRAINT fk_teacher_att_scan_card FOREIGN KEY (card_id) REFERENCES public.teacher_cards(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_scan_events fk_teacher_att_scan_day; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_scan_events
    ADD CONSTRAINT fk_teacher_att_scan_day FOREIGN KEY (day_id) REFERENCES public.teacher_attendance_days(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_attendance_scan_events fk_teacher_att_scan_teacher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_scan_events
    ADD CONSTRAINT fk_teacher_att_scan_teacher FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_scan_events fk_teacher_att_scan_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_scan_events
    ADD CONSTRAINT fk_teacher_att_scan_user FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_attendance_settings fk_teacher_att_settings_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_attendance_settings
    ADD CONSTRAINT fk_teacher_att_settings_user FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_cards fk_teacher_cards_teacher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_cards
    ADD CONSTRAINT fk_teacher_cards_teacher FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_permission_requests fk_teacher_perm_decided_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_requests
    ADD CONSTRAINT fk_teacher_perm_decided_by FOREIGN KEY (decided_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_permission_request_slots fk_teacher_perm_slots_req; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_request_slots
    ADD CONSTRAINT fk_teacher_perm_slots_req FOREIGN KEY (permission_request_id) REFERENCES public.teacher_permission_requests(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_permission_request_slots fk_teacher_perm_slots_tt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_request_slots
    ADD CONSTRAINT fk_teacher_perm_slots_tt FOREIGN KEY (timetable_entry_id) REFERENCES public.timetable_entries(id) ON DELETE CASCADE;


--
-- Name: teacher_permission_requests fk_teacher_perm_teacher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_requests
    ADD CONSTRAINT fk_teacher_perm_teacher FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_subjects fk_teacher_subjects_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_subjects
    ADD CONSTRAINT fk_teacher_subjects_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: teachers fk_teachers_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT fk_teachers_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: timetable_entries fk_timetable_entries_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT fk_timetable_entries_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: timetable_overrides fk_timetable_overrides_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT fk_timetable_overrides_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: timetable_entries fk_timetable_period; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT fk_timetable_period FOREIGN KEY (period_id) REFERENCES public.periods(id);


--
-- Name: timetables fk_timetables_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT fk_timetables_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: teacher_lesson_presence fk_tlp_att_session; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_lesson_presence
    ADD CONSTRAINT fk_tlp_att_session FOREIGN KEY (attendance_session_id) REFERENCES public.attendance_sessions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_lesson_presence fk_tlp_permission; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_lesson_presence
    ADD CONSTRAINT fk_tlp_permission FOREIGN KEY (permission_request_id) REFERENCES public.teacher_permission_requests(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: teacher_lesson_presence fk_tlp_teacher; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_lesson_presence
    ADD CONSTRAINT fk_tlp_teacher FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: teacher_lesson_presence fk_tlp_tt_entry; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_lesson_presence
    ADD CONSTRAINT fk_tlp_tt_entry FOREIGN KEY (timetable_entry_id) REFERENCES public.timetable_entries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_roles fk_user_roles_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES public.users(id) NOT VALID;


--
-- Name: users fk_users_school; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_school FOREIGN KEY (school_id) REFERENCES public.schools(id) ON DELETE RESTRICT;


--
-- Name: grade_subjects grade_subjects_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grade_subjects
    ADD CONSTRAINT grade_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- Name: grades grades_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.stages(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: lesson_substitutions lesson_substitutions_absent_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson_substitutions
    ADD CONSTRAINT lesson_substitutions_absent_teacher_id_fkey FOREIGN KEY (absent_teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: lesson_substitutions lesson_substitutions_assigned_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson_substitutions
    ADD CONSTRAINT lesson_substitutions_assigned_by_user_id_fkey FOREIGN KEY (assigned_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: lesson_substitutions lesson_substitutions_substitute_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson_substitutions
    ADD CONSTRAINT lesson_substitutions_substitute_teacher_id_fkey FOREIGN KEY (substitute_teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: lesson_substitutions lesson_substitutions_timetable_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lesson_substitutions
    ADD CONSTRAINT lesson_substitutions_timetable_entry_id_fkey FOREIGN KEY (timetable_entry_id) REFERENCES public.timetable_entries(id) ON DELETE CASCADE;


--
-- Name: notification_attachments notification_attachments_notification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_attachments
    ADD CONSTRAINT notification_attachments_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE;


--
-- Name: notification_recipients notification_recipients_notification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT notification_recipients_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE;


--
-- Name: notification_recipients notification_recipients_recipient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_recipients
    ADD CONSTRAINT notification_recipients_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_sender_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_sender_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: permission_request_recipients permission_request_recipients_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_request_recipients
    ADD CONSTRAINT permission_request_recipients_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.permission_requests(id) ON DELETE CASCADE;


--
-- Name: permission_request_recipients permission_request_recipients_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_request_recipients
    ADD CONSTRAINT permission_request_recipients_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: permission_requests permission_requests_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission_requests
    ADD CONSTRAINT permission_requests_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: section_advisors section_advisors_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_advisors
    ADD CONSTRAINT section_advisors_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE RESTRICT;


--
-- Name: section_advisors section_advisors_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_advisors
    ADD CONSTRAINT section_advisors_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: section_advisors section_advisors_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_advisors
    ADD CONSTRAINT section_advisors_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE RESTRICT;


--
-- Name: section_advisors section_advisors_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_advisors
    ADD CONSTRAINT section_advisors_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE RESTRICT;


--
-- Name: section_subject_teachers section_subject_teachers_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT section_subject_teachers_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE RESTRICT;


--
-- Name: section_subject_teachers section_subject_teachers_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT section_subject_teachers_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: section_subject_teachers section_subject_teachers_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT section_subject_teachers_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE RESTRICT;


--
-- Name: section_subject_teachers section_subject_teachers_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT section_subject_teachers_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- Name: section_subject_teachers section_subject_teachers_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subject_teachers
    ADD CONSTRAINT section_subject_teachers_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE RESTRICT;


--
-- Name: student_year_results student_year_results_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_year_results
    ADD CONSTRAINT student_year_results_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE CASCADE;


--
-- Name: student_year_results student_year_results_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_year_results
    ADD CONSTRAINT student_year_results_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_year_results student_year_results_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_year_results
    ADD CONSTRAINT student_year_results_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: teacher_barcode_tokens teacher_barcode_tokens_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_barcode_tokens
    ADD CONSTRAINT teacher_barcode_tokens_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: teacher_permission_request_slots teacher_permission_request_slots_timetable_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_permission_request_slots
    ADD CONSTRAINT teacher_permission_request_slots_timetable_entry_id_fkey FOREIGN KEY (timetable_entry_id) REFERENCES public.timetable_entries(id) ON DELETE CASCADE;


--
-- Name: teacher_subjects teacher_subjects_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_subjects
    ADD CONSTRAINT teacher_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- Name: teacher_subjects teacher_subjects_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teacher_subjects
    ADD CONSTRAINT teacher_subjects_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE RESTRICT;


--
-- Name: teachers teachers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: timetable_entries timetable_entries_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT timetable_entries_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id) ON DELETE RESTRICT;


--
-- Name: timetable_entries timetable_entries_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT timetable_entries_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- Name: timetable_entries timetable_entries_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT timetable_entries_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE RESTRICT;


--
-- Name: timetable_entries timetable_entries_timetable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_entries
    ADD CONSTRAINT timetable_entries_timetable_id_fkey FOREIGN KEY (timetable_id) REFERENCES public.timetables(id) ON DELETE CASCADE;


--
-- Name: timetable_overrides timetable_overrides_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT timetable_overrides_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.periods(id) ON DELETE RESTRICT;


--
-- Name: timetable_overrides timetable_overrides_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT timetable_overrides_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id);


--
-- Name: timetable_overrides timetable_overrides_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT timetable_overrides_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id);


--
-- Name: timetable_overrides timetable_overrides_timetable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetable_overrides
    ADD CONSTRAINT timetable_overrides_timetable_id_fkey FOREIGN KEY (timetable_id) REFERENCES public.timetables(id) ON DELETE CASCADE;


--
-- Name: timetables timetables_academic_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT timetables_academic_year_id_fkey FOREIGN KEY (academic_year_id) REFERENCES public.academic_years(id) ON DELETE RESTRICT;


--
-- Name: timetables timetables_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT timetables_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: timetables timetables_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT timetables_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE RESTRICT;


--
-- Name: timetables timetables_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.timetables
    ADD CONSTRAINT timetables_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.stages(id) ON DELETE RESTRICT;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict BsPF5ALIHzkyikwpLH3METeCYmzVSN0Pm0UyeOlV3k7aYeeM1Up49KmQ84UaO8d

