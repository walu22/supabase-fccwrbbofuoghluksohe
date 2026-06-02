


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


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    coalesce(new.raw_user_meta_data->>'role', 'customer')
  );
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."match_helpers"("p_service_type" character varying, "p_booking_date" "date", "p_booking_time" character varying, "p_location" character varying) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_archetype VARCHAR;
    v_proximity_bias FLOAT;
    v_rating_bias FLOAT;
    v_selected_helper RECORD;
BEGIN
    -- Determine Archetype Bias
    IF p_service_type IN ('indoor', 'airbnb', 'office') THEN
        v_archetype := 'CLEANING';
        v_proximity_bias := 0.5;
        v_rating_bias := 0.5;
    ELSIF p_service_type IN ('deep', 'repairs', 'moving') THEN
        v_archetype := 'TECHNICAL';
        v_proximity_bias := 0.3;
        v_rating_bias := 0.7;
    ELSE
        v_archetype := 'LOGISTICS';
        v_proximity_bias := 0.8;
        v_rating_bias := 0.2;
    END IF;

    -- Find the best available helper
    SELECT h.* INTO v_selected_helper
    FROM helpers h
    WHERE h.is_active = TRUE
      -- Check if helper is already booked at this specific date/time
      AND NOT EXISTS (
          SELECT 1 FROM helper_bookings hb
          WHERE hb.helper_id = h.id
            AND hb.booking_date = p_booking_date
            AND hb.status = 'confirmed'
            -- Basic time overlap logic (assumes a standard 2-hour window for simplicity)
            AND (
                (p_booking_time::TIME >= hb.start_time AND p_booking_time::TIME < hb.end_time) OR
                ((p_booking_time::TIME + INTERVAL '2 hours') > hb.start_time AND p_booking_time::TIME <= hb.start_time)
            )
      )
    ORDER BY 
        -- Composite Score: heavily weighted towards rating for now, as proximity requires exact lat/lng
        (h.rating * v_rating_bias) DESC, 
        h.jobs_completed DESC
    LIMIT 1;

    IF v_selected_helper.id IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN row_to_json(v_selected_helper)::JSONB;
END;
$$;


ALTER FUNCTION "public"."match_helpers"("p_service_type" character varying, "p_booking_date" "date", "p_booking_time" character varying, "p_location" character varying) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "customer_id" "uuid" NOT NULL,
    "provider_id" "uuid",
    "service_id" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "date" timestamp with time zone NOT NULL,
    "total_price" numeric(10,2) NOT NULL,
    "address" "jsonb",
    "additional_details" "jsonb",
    "confirmation_code" "text",
    "rating" integer,
    "review_comment" "text",
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "payout_status" "text" DEFAULT 'unpaid'::"text",
    "helper_id" "uuid",
    CONSTRAINT "bookings_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5))),
    CONSTRAINT "bookings_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text", 'in-progress'::"text", 'completed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."helper_bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "helper_id" "uuid",
    "booking_date" "date" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "status" character varying(50) DEFAULT 'confirmed'::character varying
);


ALTER TABLE "public"."helper_bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."helpers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "rating" numeric(3,2) DEFAULT 5.0,
    "jobs_completed" integer DEFAULT 0,
    "avatar_url" "text",
    "bio" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "hourly_rate" integer DEFAULT 55,
    "badges" "text"[] DEFAULT '{}'::"text"[]
);


ALTER TABLE "public"."helpers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."lusaka_areas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "travel_fee" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."lusaka_areas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."lusaka_estates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "area_id" "uuid",
    "name" character varying NOT NULL,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."lusaka_estates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" bigint NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "recipient_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


ALTER TABLE "public"."messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."payout_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "booking_id" "uuid",
    "helper_id" "uuid",
    "amount" numeric NOT NULL,
    "processed_at" timestamp with time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'success'::"text",
    "ip_address" "text",
    "user_agent" "text",
    "admin_id" "uuid"
);


ALTER TABLE "public"."payout_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text",
    "avatar_url" "text",
    "phone_number" "text",
    "role" "text" DEFAULT 'customer'::"text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['customer'::"text", 'provider'::"text", 'admin'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."promo_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "code" character varying(50) NOT NULL,
    "discount_percentage" integer NOT NULL,
    "is_active" boolean DEFAULT true,
    "valid_until" timestamp with time zone,
    CONSTRAINT "promo_codes_discount_percentage_check" CHECK ((("discount_percentage" > 0) AND ("discount_percentage" <= 100)))
);


ALTER TABLE "public"."promo_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."provider_details" (
    "id" "uuid" NOT NULL,
    "bio" "text",
    "hourly_rate" numeric(10,2),
    "categories" "text"[],
    "specialties" "text"[],
    "verified_identity" boolean DEFAULT false,
    "background_checked" boolean DEFAULT false,
    "rating" numeric(3,2) DEFAULT 0.0,
    "review_count" integer DEFAULT 0,
    "completion_rate" integer DEFAULT 0,
    "response_time" "text",
    "completed_jobs" integer DEFAULT 0,
    "top_provider" boolean DEFAULT false
);


ALTER TABLE "public"."provider_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referrals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "referrer_id" "uuid",
    "referral_code" "text",
    "total_credit_earned" numeric DEFAULT 0
);


ALTER TABLE "public"."referrals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."service_bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "service_type" character varying(50) NOT NULL,
    "customer_address" "text" NOT NULL,
    "booking_date" "date" NOT NULL,
    "booking_time" character varying(50) NOT NULL,
    "house_number" character varying(50),
    "estate_name" "text",
    "total_price" numeric(10,2) NOT NULL,
    "status" character varying(50) DEFAULT 'pending_review'::character varying,
    "matched_helper_id" "uuid",
    "customer_notes" "text",
    "is_notified" boolean DEFAULT false,
    "promo_code" character varying(50),
    "promo_discount_amount" numeric(10,2) DEFAULT 0.00
);


ALTER TABLE "public"."service_bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."services" (
    "id" "text" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "category" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "hourly_rate" numeric(10,2),
    "estimated_duration" "text",
    "tasks" "text"[]
);


ALTER TABLE "public"."services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vouchers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "purchaser_id" "uuid",
    "recipient_name" "text",
    "recipient_email" "text",
    "amount" numeric,
    "code" "text",
    "is_redeemed" boolean DEFAULT false
);


ALTER TABLE "public"."vouchers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."worker_applications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "first_name" "text",
    "last_name" "text",
    "phone" "text",
    "area" "text",
    "experience_years" integer,
    "status" "text" DEFAULT 'pending'::"text"
);


ALTER TABLE "public"."worker_applications" OWNER TO "postgres";


ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."helper_bookings"
    ADD CONSTRAINT "helper_bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."helpers"
    ADD CONSTRAINT "helpers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lusaka_areas"
    ADD CONSTRAINT "lusaka_areas_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."lusaka_areas"
    ADD CONSTRAINT "lusaka_areas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lusaka_estates"
    ADD CONSTRAINT "lusaka_estates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payout_logs"
    ADD CONSTRAINT "payout_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."promo_codes"
    ADD CONSTRAINT "promo_codes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."promo_codes"
    ADD CONSTRAINT "promo_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."provider_details"
    ADD CONSTRAINT "provider_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_referral_code_key" UNIQUE ("referral_code");



ALTER TABLE ONLY "public"."service_bookings"
    ADD CONSTRAINT "service_bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."worker_applications"
    ADD CONSTRAINT "worker_applications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_helper_id_fkey" FOREIGN KEY ("helper_id") REFERENCES "public"."helpers"("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id");



ALTER TABLE ONLY "public"."helper_bookings"
    ADD CONSTRAINT "helper_bookings_helper_id_fkey" FOREIGN KEY ("helper_id") REFERENCES "public"."helpers"("id");



ALTER TABLE ONLY "public"."lusaka_estates"
    ADD CONSTRAINT "lusaka_estates_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "public"."lusaka_areas"("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."payout_logs"
    ADD CONSTRAINT "payout_logs_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."payout_logs"
    ADD CONSTRAINT "payout_logs_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "public"."bookings"("id");



ALTER TABLE ONLY "public"."payout_logs"
    ADD CONSTRAINT "payout_logs_helper_id_fkey" FOREIGN KEY ("helper_id") REFERENCES "public"."helpers"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."provider_details"
    ADD CONSTRAINT "provider_details_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_referrer_id_fkey" FOREIGN KEY ("referrer_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."service_bookings"
    ADD CONSTRAINT "service_bookings_matched_helper_id_fkey" FOREIGN KEY ("matched_helper_id") REFERENCES "public"."helpers"("id");



ALTER TABLE ONLY "public"."vouchers"
    ADD CONSTRAINT "vouchers_purchaser_id_fkey" FOREIGN KEY ("purchaser_id") REFERENCES "auth"."users"("id");



CREATE POLICY "Admin view all applications" ON "public"."worker_applications" USING ((("auth"."jwt"() ->> 'email'::"text") = 'walukamubita@gmail.com'::"text"));



CREATE POLICY "Admin view all bookings" ON "public"."bookings" USING ((("auth"."jwt"() ->> 'email'::"text") = 'walukamubita@gmail.com'::"text"));



CREATE POLICY "Admin view all referrals" ON "public"."referrals" USING ((("auth"."jwt"() ->> 'email'::"text") = 'walukamubita@gmail.com'::"text"));



CREATE POLICY "Admin view all vouchers" ON "public"."vouchers" USING ((("auth"."jwt"() ->> 'email'::"text") = 'walukamubita@gmail.com'::"text"));



CREATE POLICY "Admin2 view all applications" ON "public"."worker_applications" USING ((("auth"."jwt"() ->> 'email'::"text") = 'admin@tumahelper.com'::"text"));



CREATE POLICY "Admin2 view all bookings" ON "public"."bookings" USING ((("auth"."jwt"() ->> 'email'::"text") = 'admin@tumahelper.com'::"text"));



CREATE POLICY "Admin2 view all referrals" ON "public"."referrals" USING ((("auth"."jwt"() ->> 'email'::"text") = 'admin@tumahelper.com'::"text"));



CREATE POLICY "Admin2 view all vouchers" ON "public"."vouchers" USING ((("auth"."jwt"() ->> 'email'::"text") = 'admin@tumahelper.com'::"text"));



CREATE POLICY "Admins can delete services" ON "public"."services" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins can insert services" ON "public"."services" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Admins can update services" ON "public"."services" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Allow admin read" ON "public"."service_bookings" FOR SELECT USING (true);



CREATE POLICY "Allow admin update" ON "public"."service_bookings" FOR UPDATE USING (true);



CREATE POLICY "Allow anonymous insertion" ON "public"."service_bookings" FOR INSERT WITH CHECK (true);



CREATE POLICY "Allow anonymous read of promo_codes" ON "public"."promo_codes" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Allow public select on helpers" ON "public"."helpers" FOR SELECT USING (true);



CREATE POLICY "Enable insert for everyone" ON "public"."bookings" FOR INSERT WITH CHECK (true);



CREATE POLICY "Enable insert for everyone" ON "public"."referrals" FOR INSERT WITH CHECK (true);



CREATE POLICY "Enable insert for everyone" ON "public"."vouchers" FOR INSERT WITH CHECK (true);



CREATE POLICY "Enable insert for everyone" ON "public"."worker_applications" FOR INSERT WITH CHECK (true);



CREATE POLICY "Public can read active estates" ON "public"."lusaka_estates" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Public provider details are viewable by everyone." ON "public"."provider_details" FOR SELECT USING (true);



CREATE POLICY "Public services are viewable by everyone" ON "public"."services" FOR SELECT USING (true);



CREATE POLICY "Services are viewable by everyone." ON "public"."services" FOR SELECT USING (true);



CREATE POLICY "Users can create bookings." ON "public"."bookings" FOR INSERT WITH CHECK (("auth"."uid"() = "customer_id"));



CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can send messages." ON "public"."messages" FOR INSERT WITH CHECK (("auth"."uid"() = "sender_id"));



CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can update their own bookings." ON "public"."bookings" FOR UPDATE USING ((("auth"."uid"() = "customer_id") OR ("auth"."uid"() = "provider_id")));



CREATE POLICY "Users can view their own bookings." ON "public"."bookings" FOR SELECT USING ((("auth"."uid"() = "customer_id") OR ("auth"."uid"() = "provider_id")));



CREATE POLICY "Users can view their own messages." ON "public"."messages" FOR SELECT USING ((("auth"."uid"() = "sender_id") OR ("auth"."uid"() = "recipient_id")));



CREATE POLICY "Users view own bookings" ON "public"."bookings" FOR SELECT USING (("auth"."uid"() = "customer_id"));



CREATE POLICY "Users view own referrals" ON "public"."referrals" FOR SELECT USING (("auth"."uid"() = "referrer_id"));



CREATE POLICY "Users view own vouchers" ON "public"."vouchers" FOR SELECT USING (("auth"."uid"() = "purchaser_id"));



ALTER TABLE "public"."bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."helper_bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."helpers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."lusaka_areas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."lusaka_estates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."payout_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."promo_codes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."provider_details" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."referrals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."service_bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."services" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vouchers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."worker_applications" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."match_helpers"("p_service_type" character varying, "p_booking_date" "date", "p_booking_time" character varying, "p_location" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."match_helpers"("p_service_type" character varying, "p_booking_date" "date", "p_booking_time" character varying, "p_location" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."match_helpers"("p_service_type" character varying, "p_booking_date" "date", "p_booking_time" character varying, "p_location" character varying) TO "service_role";


















GRANT ALL ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT ALL ON TABLE "public"."helper_bookings" TO "anon";
GRANT ALL ON TABLE "public"."helper_bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."helper_bookings" TO "service_role";



GRANT ALL ON TABLE "public"."helpers" TO "anon";
GRANT ALL ON TABLE "public"."helpers" TO "authenticated";
GRANT ALL ON TABLE "public"."helpers" TO "service_role";



GRANT ALL ON TABLE "public"."lusaka_areas" TO "anon";
GRANT ALL ON TABLE "public"."lusaka_areas" TO "authenticated";
GRANT ALL ON TABLE "public"."lusaka_areas" TO "service_role";



GRANT ALL ON TABLE "public"."lusaka_estates" TO "anon";
GRANT ALL ON TABLE "public"."lusaka_estates" TO "authenticated";
GRANT ALL ON TABLE "public"."lusaka_estates" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."payout_logs" TO "anon";
GRANT ALL ON TABLE "public"."payout_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."payout_logs" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."promo_codes" TO "anon";
GRANT ALL ON TABLE "public"."promo_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."promo_codes" TO "service_role";



GRANT ALL ON TABLE "public"."provider_details" TO "anon";
GRANT ALL ON TABLE "public"."provider_details" TO "authenticated";
GRANT ALL ON TABLE "public"."provider_details" TO "service_role";



GRANT ALL ON TABLE "public"."referrals" TO "anon";
GRANT ALL ON TABLE "public"."referrals" TO "authenticated";
GRANT ALL ON TABLE "public"."referrals" TO "service_role";



GRANT ALL ON TABLE "public"."service_bookings" TO "anon";
GRANT ALL ON TABLE "public"."service_bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."service_bookings" TO "service_role";



GRANT ALL ON TABLE "public"."services" TO "anon";
GRANT ALL ON TABLE "public"."services" TO "authenticated";
GRANT ALL ON TABLE "public"."services" TO "service_role";



GRANT ALL ON TABLE "public"."vouchers" TO "anon";
GRANT ALL ON TABLE "public"."vouchers" TO "authenticated";
GRANT ALL ON TABLE "public"."vouchers" TO "service_role";



GRANT ALL ON TABLE "public"."worker_applications" TO "anon";
GRANT ALL ON TABLE "public"."worker_applications" TO "authenticated";
GRANT ALL ON TABLE "public"."worker_applications" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































