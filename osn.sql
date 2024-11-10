-- Database: osn

-- DROP DATABASE IF EXISTS osn;

CREATE DATABASE osn
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_Indonesia.1252'
    LC_CTYPE = 'English_Indonesia.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE TABLE IF NOT EXISTS public.osn
(
    id integer NOT NULL DEFAULT nextval('osn_id_seq'::regclass),
    nama_peserta character varying(100) COLLATE pg_catalog."default" NOT NULL,
    gender character varying(50) COLLATE pg_catalog."default" NOT NULL,
    sekolah character varying(100) COLLATE pg_catalog."default" NOT NULL,
    provinsi character varying(100) COLLATE pg_catalog."default" NOT NULL,
    kab_kota character varying(100) COLLATE pg_catalog."default" NOT NULL,
    bidang character varying(100) COLLATE pg_catalog."default" NOT NULL,
    jenjang_lomba character varying(100) COLLATE pg_catalog."default" NOT NULL,
    jenjang_sekolah character varying(100) COLLATE pg_catalog."default" NOT NULL,
    kelas double precision,
    medali character(100) COLLATE pg_catalog."default" NOT NULL,
    prizez_tambahan character varying(100) COLLATE pg_catalog."default",
    tahun integer NOT NULL,
    CONSTRAINT osn_pkey PRIMARY KEY (id)
)

COPY osn
FROM 'C:\Users\Hp\Downloads\osn.csv'
DELIMITER ','
CSV HEADER;

-- show all table
select * from osn

-- 1) how many participants by each year in the OSN from 2009 to 2024? 
SELECT tahun, COUNT(*) AS total_participants FROM osn GROUP BY tahun ORDER BY tahun

-- 2) how is the gender distribution in OSN?
SELECT gender, COUNT(*) AS count_by_gender FROM osn GROUP BY gender

-- 3) how has the gender distribution of participants change over the years?
SELECT tahun, gender, COUNT(*) AS count_by_gender FROM osn GROUP BY tahun, gender ORDER BY tahun, gender

-- 4) how many participants are there at each school level contest SMP vs. SMA in the OSN?
SELECT jenjang_lomba, COUNT(*) AS total_participants FROM osn GROUP BY jenjang_lomba

-- 5) what provinces had the highest total participation over the entire time span?
SELECT provinsi, COUNT(*) AS total_participants FROM osn GROUP BY provinsi ORDER BY total_participants desc 

-- 6) get the top 5 provinces based on the number of participants each year
WITH RankedProvinces AS (
	SELECT tahun, provinsi, COUNT(*) AS total_participants, ROW_NUMBER() OVER (PARTITION BY tahun ORDER BY COUNT(*) DESC) AS rank 
	FROM osn 
	GROUP BY provinsi, tahun
)SELECT tahun, provinsi, total_participants 
FROM RankedProvinces 
WHERE rank <= 5 
ORDER BY tahun, rank;

-- 7) which provinces produced the most medal in osn?
SELECT provinsi, COUNT(*) AS total_medals FROM osn
WHERE medali != 'Partisipan'
GROUP BY provinsi
ORDER BY total_medals DESC

-- more detail 
SELECT 
    provinsi,
	COUNT(*) AS total_medal,
    COUNT(CASE WHEN medali = 'Emas' THEN 1 END) AS jumlah_emas,
    COUNT(CASE WHEN medali = 'Perak' THEN 1 END) AS jumlah_perak,
    COUNT(CASE WHEN medali = 'Perunggu' THEN 1 END) AS jumlah_perunggu,
    COUNT(CASE WHEN medali = 'Harapan' THEN 1 END) AS jumlah_harapan
FROM osn
WHERE medali != 'Partisipan'
GROUP BY provinsi
ORDER BY total_medal DESC


-- 8) which provinces produced the most medal in osn in each year?
SELECT tahun, provinsi, COUNT(*) AS total_medals
FROM osn
WHERE medali != 'Partisipan'
GROUP BY tahun, provinsi
ORDER BY tahun, total_medals DESC


-- 9) How many of each type of medal (Emas, Perak, Perunggu, Harapan) did each province earn each year in the OSN competition?
SELECT 
    tahun,
    provinsi,
    COUNT(CASE WHEN medali = 'Emas' THEN 1 END) AS jumlah_emas,
    COUNT(CASE WHEN medali = 'Perak' THEN 1 END) AS jumlah_perak,
    COUNT(CASE WHEN medali = 'Perunggu' THEN 1 END) AS jumlah_perunggu,
    COUNT(CASE WHEN medali = 'Harapan' THEN 1 END) AS jumlah_harapan
FROM osn
WHERE medali != 'Partisipan'
GROUP BY tahun, provinsi
ORDER BY tahun, jumlah_emas DESC, jumlah_perak DESC, jumlah_perunggu DESC, jumlah_harapan DESC;

-- 10) what is the top 1 province by medal count for each year?
WITH RankedProvinces AS(
    SELECT tahun, provinsi, COUNT(*) AS total_medals, ROW_NUMBER() OVER (PARTITION BY tahun ORDER BY COUNT(*) DESC) AS rank
    FROM osn
    WHERE medali IN ('Emas', 'Perak', 'Perunggu')
    GROUP BY tahun, provinsi 
)SELECT tahun, provinsi, total_medals
FROM RankedProvinces
WHERE rank = 1
ORDER BY tahun;

-- 11) which provinces produced the most "emas" medal in osn?
SELECT provinsi, COUNT(*) AS total_gold_medal
FROM osn
WHERE medali = 'Emas'
GROUP BY provinsi
ORDER BY total_gold_medal DESC

-- 12) which province has the lowest proportion of medals awarded compared to its total number of participants?
WITH ProvinceParticipation AS (
    SELECT provinsi, COUNT(*) AS total_participants
    FROM osn
    GROUP BY provinsi
),ProvinceMedals AS (
    SELECT provinsi, COUNT(*) AS total_medals
    FROM osn
    WHERE medali IN ('Emas', 'Perak', 'Perunggu')
    GROUP BY provinsi
),MedalRatio AS (
    SELECT 
		pp.provinsi, 
		pp.total_participants, 
		COALESCE(pm.total_medals, 0) AS total_medals, 
        COALESCE(pm.total_medals, 0) * 1.0 / pp.total_participants AS medal_ratio 
    FROM ProvinceParticipation pp
    LEFT JOIN ProvinceMedals pm ON pp.provinsi = pm.provinsi
)SELECT provinsi, total_participants, total_medals, medal_ratio
FROM MedalRatio
ORDER BY medal_ratio ASC;

-- 13) At SMA level, which subject has the most participants?
SELECT bidang AS bidang_sma, COUNT(*) as total_participants
FROM osn
WHERE jenjang_lomba = 'SMA'
GROUP BY bidang_sma
ORDER BY total_participants DESC

-- 14) what are the trends in OSN subjects each year at SMA level?
SELECT tahun, bidang AS bidang_sma, COUNT(*) as total_participants
FROM osn
WHERE jenjang_lomba = 'SMA'
GROUP BY tahun, bidang_sma
ORDER BY tahun ASC, total_participants DESC

-- 15) At SMP level, which subject has the most participants?
SELECT bidang AS bidang_smp, COUNT(*) as total_participants
FROM osn
WHERE jenjang_lomba = 'SMP'
GROUP BY bidang_smp
ORDER BY total_participants DESC

-- 16) How did participation in each SMP subject trend over the years, especially with the split of IPA into Biologi and Fisika from 2010 to 2014?
SELECT bidang AS bidang_smp, tahun, COUNT(*) as total_participants
FROM osn
WHERE jenjang_lomba = 'SMP' 
GROUP BY bidang_smp, tahun
ORDER BY tahun ASC, total_participants DESC
-- answear ternyata semua subject tiap tahunnya rata2 memiliki jumlah peserta yang sama
-- this script helps see if the most popular subject overall was consistently popular each year or if there were shifts in preferences.
-- try to see if the combination later make the participant increase, but the answear is every subject always have the same total participant each year

-- 17) How many SMP students participate in SMA contests?
SELECT COUNT(*) as smp_partisipant_in_sma_comp
FROM osn
WHERE jenjang_sekolah = 'SMP' and jenjang_lomba = 'SMA'

-- 18) how many SMA student participate in SMA contests?
SELECT COUNT(*) as sma_partisipant_in_sma_comp
FROM osn
WHERE jenjang_sekolah = 'SMA'

-- 19) Compare the performance of SMP student in SMA contests compared to regular SMA students?
SELECT jenjang_sekolah, COUNT(*) AS total_medals
FROM osn
WHERE jenjang_lomba = 'SMA' and medali != 'Partisipan'
GROUP BY jenjang_sekolah

-- or try to see a more detailed comparison
SELECT 
    jenjang_sekolah AS school_level, 
    medali AS medal_type, 
    COUNT(*) AS total_medals
FROM 
    osn
WHERE 
    jenjang_lomba = 'SMA' and medali != 'Partisipan'
GROUP BY 
    jenjang_sekolah, medali
ORDER BY 
    school_level DESC, medal_type ASC;

-- 20) how does the gender distribution of participants vary across subjects in the SMA level competition?
SELECT bidang, gender, COUNT(*) AS participant_by_gender_count
FROM osn
WHERE jenjang_lomba = 'SMA'
GROUP BY bidang, gender
ORDER BY bidang ASC, participant_by_gender_count DESC

-- 21) how does the gender distribution of participants vary across subjects in the SMP level competition? 
SELECT bidang, gender, COUNT(*) AS participant_by_gender_count
FROM osn
WHERE jenjang_lomba = 'SMP'
GROUP BY bidang, gender
ORDER BY bidang ASC, participant_by_gender_count DESC

-- 22) Top 10 school that sent the most participants in SMA level competition
SELECT sekolah, COUNT(*) AS total_participants 
FROM osn 
WHERE jenjang_lomba = 'SMA' 
GROUP BY sekolah 
ORDER BY total_participants DESC LIMIT 10

-- 23) Top 10 school that sent the most participants in SMP level competition
SELECT sekolah, COUNT(*) AS total_participants 
FROM osn 
WHERE jenjang_lomba = 'SMP' 
GROUP BY sekolah 
ORDER BY total_participants DESC LIMIT 10

-- 24) Top 10 school with the most medal in SMA level competition
SELECT sekolah, COUNT(*) AS total_medals 
FROM osn 
WHERE jenjang_lomba = 'SMA' AND medali != 'Partisipan'
GROUP BY sekolah 
ORDER BY total_medals DESC LIMIT 10

-- 25) Top 10 school with the most medal in SMP level competition
SELECT sekolah, COUNT(*) AS total_medals 
FROM osn 
WHERE jenjang_lomba = 'SMP' AND medali != 'Partisipan'
GROUP BY sekolah 
ORDER BY total_medals DESC LIMIT 10


