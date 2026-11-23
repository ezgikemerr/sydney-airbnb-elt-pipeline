
-- =====================================================
-- Part 4: Ad-hoc Analysis
-- =====================================================

-- ============================================================
-- Part 4(a) - Demographic Differences Between the Top 3 and
-- Lowest 3 Performing LGAs
--
-- What this query does:
-- Calculates estimated revenue per active listing for each LGA.
-- Ranks LGAs and identifies the top 3 and lowest 3 performers.
-- Links the selected LGAs with Census demographic data.
-- Compares median age, average household size and age-group
-- distributions between the top and lowest performing LGAs.
--
-- Rank LGAs by estimated revenue per active listing over the
-- 12-month Airbnb period. Listing neighbourhoods are mapped to
-- LGAs by first matching suburb_name and, where no suburb match
-- exists, falling back to lga_name.
--
-- The top 3 and lowest 3 LGAs are then compared using Census
-- demographic measures including median age, average household
-- size and age-group distributions.
-- ============================================================

WITH suburb_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(suburb_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

lga_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(lga_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

listing_locations AS (

    SELECT
        dl.listing_scd_id,
        COALESCE(sm.lga_code, lm.lga_code) AS lga_code,
        COALESCE(sm.lga_name, lm.lga_name) AS lga_name
    FROM gold.dim_listing dl

    LEFT JOIN suburb_mapping sm
        ON LOWER(TRIM(dl.listing_neighbourhood)) = sm.location_name

    LEFT JOIN lga_mapping lm
        ON LOWER(TRIM(dl.listing_neighbourhood)) = lm.location_name
       AND sm.lga_code IS NULL

),

lga_performance AS (

    SELECT
        ll.lga_code,
        ll.lga_name,

        SUM(f.estimated_revenue)
            / NULLIF(
                COUNT(DISTINCT f.listing_id)
                    FILTER (WHERE f.is_active = 1),
                0
            ) AS revenue_per_active_listing

    FROM gold.fact_listings f

    JOIN listing_locations ll
        ON f.listing_scd_id = ll.listing_scd_id

    WHERE f.is_active = 1

    GROUP BY
        ll.lga_code,
        ll.lga_name

),

ranked_lgas AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY revenue_per_active_listing DESC
        ) AS top_rank,

        ROW_NUMBER() OVER (
            ORDER BY revenue_per_active_listing ASC
        ) AS bottom_rank

    FROM lga_performance

),

selected_lgas AS (

    SELECT
        *,
        CASE
            WHEN top_rank <= 3 THEN 'Top 3'
            WHEN bottom_rank <= 3 THEN 'Lowest 3'
        END AS performance_group

    FROM ranked_lgas

    WHERE top_rank <= 3
       OR bottom_rank <= 3

)

SELECT
    s.performance_group,
    s.lga_name,

    ROUND(
        s.revenue_per_active_listing::numeric,
        2
    ) AS revenue_per_active_listing,

    g2.median_age_persons,
    g2.average_household_size,

    ROUND(
        100.0 * (
            g1.age_0_4_yr_p +
            g1.age_5_14_yr_p +
            g1.age_15_19_yr_p
        ) / NULLIF(g1.tot_p_p, 0),
        2
    ) AS age_0_19_pct,

    ROUND(
        100.0 * (
            g1.age_20_24_yr_p +
            g1.age_25_34_yr_p
        ) / NULLIF(g1.tot_p_p, 0),
        2
    ) AS age_20_34_pct,

    ROUND(
        100.0 * (
            g1.age_35_44_yr_p +
            g1.age_45_54_yr_p
        ) / NULLIF(g1.tot_p_p, 0),
        2
    ) AS age_35_54_pct,

    ROUND(
        100.0 * (
            g1.age_55_64_yr_p +
            g1.age_65_74_yr_p +
            g1.age_75_84_yr_p +
            g1.age_85ov_p
        ) / NULLIF(g1.tot_p_p, 0),
        2
    ) AS age_55_plus_pct

FROM selected_lgas s

LEFT JOIN gold.ref_census_g01 g1
    ON g1.lga_code_2016 = s.lga_code::text

LEFT JOIN gold.ref_census_g02 g2
    ON g2.lga_code_2016 = s.lga_code::text

ORDER BY
    CASE
        WHEN s.performance_group = 'Top 3' THEN 1
        ELSE 2
    END,

    CASE
        WHEN s.performance_group = 'Top 3'
        THEN s.revenue_per_active_listing
    END DESC,

    CASE
        WHEN s.performance_group = 'Lowest 3'
        THEN s.revenue_per_active_listing
    END ASC;
    
-- ============================================================
-- Part 4(b) - Correlation Between Median Age and Revenue
-- per Active Listing
--
-- What this query does:
-- Calculates revenue per active listing for each neighbourhood.
-- Maps each listing neighbourhood to its corresponding LGA.
-- Retrieves median age from the Census data.
-- Calculates the Pearson correlation between median age and
-- revenue per active listing across neighbourhoods.
--    
-- Calculate the correlation between the median age of the
-- population in the corresponding LGA (from Census data) and
-- the average estimated revenue per active listing for each
-- listing neighbourhood over the 12-month Airbnb period.
--
-- Listing neighbourhoods are mapped to an LGA by first matching
-- suburb_name and, where no suburb match exists, falling back
-- to lga_name.
-- ============================================================

WITH suburb_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(suburb_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

lga_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(lga_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

listing_neighbourhood_lga AS (

    SELECT
        d.listing_neighbourhood,
        COALESCE(sm.lga_code, lm.lga_code) AS lga_code,
        COALESCE(sm.lga_name, lm.lga_name) AS lga_name

    FROM gold.dim_listing d

    LEFT JOIN suburb_mapping sm
        ON LOWER(TRIM(d.listing_neighbourhood)) = sm.location_name

    LEFT JOIN lga_mapping lm
        ON LOWER(TRIM(d.listing_neighbourhood)) = lm.location_name
       AND sm.lga_code IS NULL

    GROUP BY
        d.listing_neighbourhood,
        COALESCE(sm.lga_code, lm.lga_code),
        COALESCE(sm.lga_name, lm.lga_name)

),

neighbourhood_revenue AS (

    SELECT
        listing_neighbourhood,
        AVG(avg_estimated_revenue_per_active_listing)
            AS avg_revenue_per_active_listing

    FROM gold.dm_listing_neighbourhood

    GROUP BY
        listing_neighbourhood

),

neighbourhood_demographics AS (

    SELECT
        n.listing_neighbourhood,
        l.lga_name,
        g2.median_age_persons,
        n.avg_revenue_per_active_listing

    FROM neighbourhood_revenue n

    JOIN listing_neighbourhood_lga l
        ON LOWER(TRIM(n.listing_neighbourhood))
         = LOWER(TRIM(l.listing_neighbourhood))

    JOIN gold.ref_census_g02 g2
        ON g2.lga_code_2016 = l.lga_code::text

)

SELECT
    COUNT(*) AS neighbourhood_count,

    ROUND(
        CORR(
            median_age_persons::numeric,
            avg_revenue_per_active_listing::numeric
        )::numeric,
        4
    ) AS median_age_revenue_correlation

FROM neighbourhood_demographics;

-- ============================================================
-- Part 4(c) - Best Listing Type for the Top 5 Neighbourhoods
--
-- Identify the top 5 listing neighbourhoods based on average
-- estimated revenue per active listing over the 12-month period.
-- For each of these neighbourhoods, identify the property type,
-- room type and accommodates combination that generated the
-- highest number of stays.
-- 
-- What this query does:
-- Identifies the top 5 listing neighbourhoods based on average
-- estimated revenue per active listing over the 12-month period.
-- For each top neighbourhood, groups listings by property type,
-- room type and accommodates.
-- Calculates the total number of stays for each listing type.
-- Selects the listing type with the highest number of stays
-- within each of the top 5 neighbourhoods.
-- ============================================================

WITH top_neighbourhoods AS (

    SELECT
        listing_neighbourhood,
        AVG(avg_estimated_revenue_per_active_listing)
            AS avg_revenue_per_active_listing
    FROM gold.dm_listing_neighbourhood
    GROUP BY
        listing_neighbourhood
    ORDER BY
        avg_revenue_per_active_listing DESC
    LIMIT 5

),

listing_performance AS (

    SELECT
        dl.listing_neighbourhood,
        dl.property_type,
        dl.room_type,
        dl.accommodates,

        SUM(f.number_of_stays) AS total_stays,

        SUM(f.estimated_revenue)
            / NULLIF(
                COUNT(DISTINCT f.listing_id)
                    FILTER (WHERE f.is_active = 1),
                0
            ) AS revenue_per_active_listing

    FROM gold.fact_listings f

    JOIN gold.dim_listing dl
        ON f.listing_scd_id = dl.listing_scd_id

    JOIN top_neighbourhoods tn
        ON LOWER(TRIM(dl.listing_neighbourhood))
         = LOWER(TRIM(tn.listing_neighbourhood))

    GROUP BY
        dl.listing_neighbourhood,
        dl.property_type,
        dl.room_type,
        dl.accommodates

),

ranked_types AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY listing_neighbourhood
            ORDER BY total_stays DESC
        ) AS stay_rank

    FROM listing_performance

)

SELECT
    listing_neighbourhood,
    property_type,
    room_type,
    accommodates,
    total_stays,
    ROUND(
        revenue_per_active_listing::numeric,
        2
    ) AS revenue_per_active_listing

FROM ranked_types

WHERE stay_rank = 1

ORDER BY
    total_stays DESC;

-- ============================================================
-- Part 4(d) - Distribution of Multiple Listings Across LGAs
--
-- Determine whether hosts with multiple Airbnb listings
-- concentrate their properties within the same LGA or
-- distribute them across multiple LGAs.

-- What this query does:
-- Identifies hosts who own more than one Airbnb listing.
-- Maps each of their listings to its corresponding LGA.
-- Counts the number of distinct LGAs associated with each host.
-- Classifies hosts as having listings within the same LGA or
-- across multiple LGAs.
-- Calculates the number and percentage of hosts in each group.
-- ============================================================

WITH suburb_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(suburb_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

lga_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(lga_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

listing_locations AS (

    SELECT
        dl.listing_id,
        dl.host_id,
        COALESCE(sm.lga_code, lm.lga_code) AS lga_code,
        COALESCE(sm.lga_name, lm.lga_name) AS lga_name

    FROM gold.dim_listing dl

    LEFT JOIN suburb_mapping sm
        ON LOWER(TRIM(dl.listing_neighbourhood))
         = sm.location_name

    LEFT JOIN lga_mapping lm
        ON LOWER(TRIM(dl.listing_neighbourhood))
         = lm.location_name
       AND sm.lga_code IS NULL

),

host_listing_summary AS (

    SELECT
        host_id,
        COUNT(DISTINCT listing_id) AS listing_count,
        COUNT(DISTINCT lga_code) AS lga_count

    FROM listing_locations

    WHERE lga_code IS NOT NULL

    GROUP BY
        host_id

    HAVING COUNT(DISTINCT listing_id) > 1

),

distribution AS (

    SELECT
        CASE
            WHEN lga_count = 1
                THEN 'Same LGA'
            ELSE 'Multiple LGAs'
        END AS distribution_type,

        COUNT(*) AS host_count

    FROM host_listing_summary

    GROUP BY
        CASE
            WHEN lga_count = 1
                THEN 'Same LGA'
            ELSE 'Multiple LGAs'
        END

)

SELECT
    distribution_type,
    host_count,

    ROUND(
        100.0 * host_count
        / SUM(host_count) OVER (),
        2
    ) AS percentage_of_multiple_listing_hosts

FROM distribution

ORDER BY
    host_count DESC;


-- ============================================================
-- Part 4(e) - Single-Listing Hosts and Mortgage Coverage
--
-- Determine whether the estimated revenue of hosts with exactly
-- one Airbnb listing covers the annualised median mortgage
-- repayment in their corresponding LGA.
--
-- The LGA is determined by first matching suburb_name and,
-- where no suburb match exists, falling back to lga_name.

-- What this query does:
-- Identifies hosts with exactly one Airbnb listing.
-- Calculates their estimated revenue over the 12-month period.
-- Maps each listing to its corresponding LGA.
-- Annualises the Census median monthly mortgage repayment
--   by multiplying it by 12.
-- Determines whether each host's estimated revenue is sufficient
--   to cover the annualised median mortgage repayment.
-- Calculates the percentage of single-listing hosts that can
--   cover the mortgage in each LGA and ranks the LGAs accordingly.
-- ============================================================

WITH suburb_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(suburb_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

lga_mapping AS (

    SELECT DISTINCT
        LOWER(TRIM(lga_name)) AS location_name,
        lga_code,
        lga_name
    FROM gold.dim_location

),

single_listing_hosts AS (

    SELECT
        host_id,
        MIN(listing_id) AS listing_id
    FROM gold.dim_listing
    GROUP BY host_id
    HAVING COUNT(DISTINCT listing_id) = 1

),

single_listings AS (

    SELECT DISTINCT
        slh.host_id,
        slh.listing_id,
        dl.listing_neighbourhood

    FROM single_listing_hosts slh

    JOIN gold.dim_listing dl
        ON slh.listing_id = dl.listing_id

),

listing_locations AS (

    SELECT
        sl.host_id,
        sl.listing_id,

        COALESCE(
            sm.lga_code,
            lm.lga_code
        ) AS lga_code,

        COALESCE(
            sm.lga_name,
            lm.lga_name
        ) AS lga_name

    FROM single_listings sl

    LEFT JOIN suburb_mapping sm
        ON LOWER(TRIM(sl.listing_neighbourhood)) = sm.location_name

    LEFT JOIN lga_mapping lm
        ON LOWER(TRIM(sl.listing_neighbourhood)) = lm.location_name
       AND sm.lga_code IS NULL

),

host_revenue AS (

    SELECT
        slh.host_id,
        slh.listing_id,

        SUM(f.estimated_revenue)
            AS estimated_revenue_12_months

    FROM single_listing_hosts slh

    JOIN gold.fact_listings f
        ON f.listing_id = slh.listing_id

    GROUP BY
        slh.host_id,
        slh.listing_id

),

host_mortgage_comparison AS (

    SELECT
        ll.host_id,
        ll.listing_id,
        ll.lga_code,
        ll.lga_name,
        hr.estimated_revenue_12_months,
        g2.median_mortgage_repay_monthly,

        g2.median_mortgage_repay_monthly * 12
            AS annualised_median_mortgage,

        CASE
            WHEN hr.estimated_revenue_12_months >=
                 g2.median_mortgage_repay_monthly * 12
            THEN 1
            ELSE 0
        END AS can_cover_mortgage

    FROM host_revenue hr

    JOIN listing_locations ll
        ON hr.host_id = ll.host_id
       AND hr.listing_id = ll.listing_id

    LEFT JOIN gold.ref_census_g02 g2
        ON g2.lga_code_2016 = ll.lga_code::text

)

SELECT
    lga_name,

    COUNT(*) AS single_listing_host_count,

    SUM(can_cover_mortgage) AS hosts_that_can_cover,

    ROUND(
        100.0 * SUM(can_cover_mortgage)
        / NULLIF(COUNT(*), 0),
        2
    ) AS percentage_hosts_can_cover,

    ROUND(
        AVG(estimated_revenue_12_months)::numeric,
        2
    ) AS avg_estimated_revenue_12_months,

    ROUND(
        AVG(annualised_median_mortgage)::numeric,
        2
    ) AS annualised_median_mortgage

FROM host_mortgage_comparison

WHERE lga_name IS NOT NULL
  AND annualised_median_mortgage IS NOT NULL

GROUP BY
    lga_name

ORDER BY
    percentage_hosts_can_cover DESC,
    single_listing_host_count DESC;

