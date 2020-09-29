# From the project README:

# The logic to restrict the query to pulling only SRBP data is incorporated into
# both the `srbp_birds` and `additional_bird_species` queries.  However, the
# query is isolated independently in `SRBP_surveys.R` in this respository for
# convenience for spot-checking that the appropriate surveys are being pulled.
# One easy check is that the SRBP surveys are conducted by one birder only. This
# was M. Banville in early years of the project, and K. Godbeer more recently.
# The only exception being 2017 when multiple birders contributed (but in 2017
# only).

srbp_surveys <- dbGetQuery(mysql_prod, "
  SELECT
    surveys.survey_id,
    sites.site_code,
    SUBSTRING_INDEX(sites.site_code, '_', 1) AS reach,
    surveys.survey_date,
    surveys.observer
  FROM lter34birds.surveys
  JOIN lter34birds.sites ON (surveys.site_id = sites.site_id)
  JOIN (
    SELECT
      SUBSTRING_INDEX(sites.site_code, '_', 1) AS reach,
      surveys.survey_date,
      surveys.observer
    FROM lter34birds.surveys
    JOIN lter34birds.sites ON (surveys.site_id = sites.site_id)
    WHERE
      sites.sample LIKE 'SRBP'
    GROUP BY
      reach,
      surveys.survey_date,
      surveys.observer
    HAVING
      count(*) > 1
    ) AS subquery ON (
    reach = subquery.reach AND
    surveys.survey_date = subquery.survey_date AND
    surveys.observer = subquery.observer
  )
  ORDER BY survey_date;")
