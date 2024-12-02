CREATE TABLE actors (
    actorid TEXT PRIMARY KEY,
    actor_name TEXT NOT NULL,
    films JSONB,
    quality_class TEXT CHECK (quality_class IN ('star', 'good', 'average', 'bad')),
    is_active BOOLEAN NOT NULL
);

INSERT INTO actors (actorid, actor_name, films, quality_class, is_active)
SELECT
    actorid AS actorid,
    actor AS actor_name,
    jsonb_agg(
        jsonb_build_object(
            'film', film,
            'votes', votes,
            'rating', rating,
            'filmid', filmid
        )
    ) AS films,
    CASE
        WHEN AVG(rating) FILTER (WHERE year = EXTRACT(YEAR FROM CURRENT_DATE)) > 8 THEN 'star'
        WHEN AVG(rating) FILTER (WHERE year = EXTRACT(YEAR FROM CURRENT_DATE)) > 7 THEN 'good'
        WHEN AVG(rating) FILTER (WHERE year = EXTRACT(YEAR FROM CURRENT_DATE)) > 6 THEN 'average'
        ELSE 'bad'
    END AS quality_class,
    MAX(year) = EXTRACT(YEAR FROM CURRENT_DATE) AS is_active
FROM actor_films
GROUP BY actorid, actor;


CREATE TABLE actors_history_scd (
    actorid TEXT,
    actor_name TEXT NOT NULL,
    quality_class TEXT CHECK (quality_class IN ('star', 'good', 'average', 'bad')),
    is_active BOOLEAN NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (actorid, start_date)
);

INSERT INTO actors_history_scd (actorid, actor_name, quality_class, is_active, start_date, end_date)
SELECT
    actorid,
    actor_name,
    quality_class,
    is_active,
    CURRENT_DATE AS start_date,
    NULL AS end_date
FROM actors
WHERE NOT EXISTS (
    SELECT 1
    FROM actors_history_scd
    WHERE actorid = actors.actorid
    AND start_date = CURRENT_DATE
);

WITH updated_data AS (
    SELECT
        a.actorid,
        a.actor_name,
        a.quality_class,
        a.is_active
    FROM actors a
)

UPDATE actors_history_scd
SET end_date = CURRENT_DATE - INTERVAL '1 day'
FROM updated_data
WHERE actors_history_scd.actorid = updated_data.actorid
  AND actors_history_scd.end_date IS NULL
  AND actors_history_scd.start_date != CURRENT_DATE
  AND (
      actors_history_scd.quality_class != updated_data.quality_class
      OR actors_history_scd.is_active != updated_data.is_active
  );

SELECT
    actorid,
    actor_name,
    quality_class,
    is_active,
    CURRENT_DATE AS start_date,
    NULL AS end_date
FROM actors;



