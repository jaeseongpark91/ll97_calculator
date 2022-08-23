SELECT *
FROM (
	SELECT
	  site_name AS "ESC Site Name",
    current_emissions.site_id AS "ESC Site ID",
	  total_current_emissions_mCo2e AS 'Current Emissions (mTCo2e)',
	  ROUND(emissions_caps.emissions_cap_2024_mTCo2e,2) AS "Emissions Cap 2024 (mTCO2e)",
	  ROUND(emissions_caps.emissions_cap_2030_mTCo2e,2) AS "Emissions Cap 2030 (mTCO2e)",
	CASE
		WHEN (emissions_caps.emissions_cap_2024_mTCo2e > current_emissions.total_current_emissions_mCo2e) THEN 0
		ELSE ROUND((current_emissions.total_current_emissions_mCo2e - emissions_caps.emissions_cap_2024_mTCo2e) * 268, 0)
	END AS "Estimated Fine ($) 2024",
	CASE
		WHEN (emissions_caps.emissions_cap_2030_mTCo2e > current_emissions.total_current_emissions_mCo2e) THEN 0
		ELSE ROUND((current_emissions.total_current_emissions_mCo2e - emissions_caps.emissions_cap_2030_mTCo2e) * 268, 0)
	END AS "Estimated Fine ($) 2030",
	property_dashboard_link AS "Property Cluvio Board Link"
	FROM (
	  	SELECT
	  		site_id,
	  		site_name,
	  		property_dashboard_link,
	  		SUM(dummy_total) AS total_current_emissions_mCo2e
	  	FROM (
	  		SELECT
	  			usage_by_utility.site_id,
	  			usage_by_utility.site_name,
	  			usage_by_utility.property_dashboard_link,
	  			(
    				COALESCE(electric_mTCo2e,0) +
    				COALESCE(gas_mTCo2e,0) +
    				COALESCE(oil_2_mTCo2e,0) +
    				COALESCE(oil_4_mTCo2e,0) +
    				COALESCE(oil_6_mTCo2e,0) +
    				COALESCE(oil_uk_mTCo2e,0) +
    				COALESCE(oil_um_mTCo2e,0) +
    				COALESCE(propane_mTCo2e,0) +
    				COALESCE(steam_mTCo2e,0)
	  			) AS dummy_total
	  		FROM (
	  		SELECT
				ss.site_id,
				spa.name as site_name,
				ss.name,
				sssu.property_scorecard_utility_scorecards_id,
				su.id as "score_utility_id",
				su.utility_account_id,
				SUM(su.total_annual_energy_used) AS "total energy used",
		    ua.utility_type AS utility_type,
				SUM(CASE WHEN ua.utility_type = 'E' THEN su.total_annual_energy_used * ecftkb.factor END) * 0.00008469 AS electric_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'G' THEN su.total_annual_energy_used * ecftkb.factor END) * 0.00005311  AS gas_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'Oil #2' THEN su.total_annual_energy_used * ecftkb.factor END) * 0.00007421 AS oil_2_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'Oil #4' THEN su.total_annual_energy_used  * ecftkb.factor END) * 0.00007529 AS oil_4_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'Oil #6' THEN su.total_annual_energy_used * ecftkb.factor END) * 0.00007535 AS oil_6_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'Unknown Oil kbtu' THEN su.total_annual_energy_used END) * 0.00007421 AS oil_uk_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'Unknown Oil mmbtu' THEN su.total_annual_energy_used * 1000 END) * 0.00007421 AS oil_um_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'P' THEN su.total_annual_energy_used * ecftkb.factor END) * 0.0000627 AS propane_mTCo2e,
				SUM(CASE WHEN ua.utility_type = 'S' THEN su.total_annual_energy_used * ecftkb.factor END) * 0.00004493 AS steam_mTCo2e,
				CONCAT('<a href=https://app.cluvio.com/dashboards/z926-3nmo-9pdr?filters=%7B%22scorecard%22%3A%5B%22', REPLACE(ss.name, " ", "%20"), '%22%5D%2C%22site_id%22%3A%5B%22', ss.site_id , '%22%5D%7D> Go to Property Dashboard </a>') AS property_dashboard_link
			FROM esc_prod_db.score_site ss
			JOIN esc_prod_db.score_site_score_utility sssu
				ON sssu.property_scorecard_utility_scorecards_id = ss.id
			JOIN esc_prod_db.score_utility su
				ON sssu.utility_scorecard_id = su.id
			JOIN (
					SELECT
						u.id as 'utility_account_id',
						u.who_pays,
						u.units,
						u.site_id,
						u.utility_type AS 'original_utility_type',
  					CASE
  						WHEN (utility_type = "O" AND units = 'Oil #2 Gallons') THEN "Oil #2"
  						WHEN (utility_type = "O" AND units = 'Oil #4 Gallons') THEN "Oil #4"
  						WHEN (utility_type = "O" AND units = 'Oil #6 Gallons') THEN "Oil #6"
  						WHEN (utility_type = "O" AND units = 'kBTU (1000 BTU)') THEN "Unknown Oil kbtu"
  						WHEN (utility_type = "O" AND units = 'mmBTU (Million BTU)') THEN "Unknown Oil mmbtu"
  						ELSE utility_type
  					END AS utility_type
					FROM esc_prod_db.utility_account u
					LEFT JOIN esc_prod_db.site ON site.id = u.site_id
					JOIN esc_prod_db.view_properties_unfiltered vpu ON vpu.id = site.id AND vpu.billable_status = 'Billable'
					WHERE site.portfolio_id IN () #Add portfolio IDs here
					# NYC Zip codes
	          AND site.zip_code IN (10001,10002,10003,10004,10005,10006,10007,10009,10010,10011,10012,10013,10014,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030,10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10044,10045,10055,10065,10069,10075,
                     10103,10105,10106,10110,10118,10119,10120,10121,10122,10123,10128,10151,10152,10155,10158,10165,10169,10170,10175,10176,10271,10278,10280,10281,10282,10301,10302,10303,10304,10305,10306,10307,10308,10309,10310,10312,10314,10451,10452,10453,10454,10455,10456,10457,
                     10458,10459,10460,10461,10462,10463,10464,10465,10466,10467,10468,10469,10470,10471,10472,10473,10474,10475,11001,11004,11005,11040,11096,11101,11102,11103,11104,11105,11106,11109,11201,11203,11204,11205,11206,11207,11208,11209,11210,11211,11212,11213,11214,11215,
                     11216,11217,11218,11219,11220,11221,11222,11223,11224,11225,11226,11228,11229,11230,11231,11232,11233,11234,11235,11236,11237,11238,11239,11241,11249,11251,11354,11355,11356,11357,11358,11359,11360,11361,11362,11363,11364,11365,11366,11367,11368,11369,11370,11371,
		     11372,11373,11374,11375,11377,11378,11379,11385,11411,11412,11413,11414,11415,11416,11417,11418,11419,11420,11421,11422,11423,11426,11427,11428,11429,11430,11432,11433,11434,11435,11436,11451,11691,11692,11693,11694,11695,11697,12345)
				) AS ua ON ua.utility_account_id = su.utility_account_id
			LEFT JOIN esc_prod_db.site s
				ON s.id = ua.site_id
			LEFT JOIN esc_prod_db.space spa
				ON spa.id = s.id and spa.parent_space_id is null
			JOIN esc_prod_db.view_properties_unfiltered vpu ON vpu.id = s.id AND vpu.billable_status = 'Billable'
			LEFT JOIN fannie_mae.energy_conversion_factors_to_kBtu ecftkb
				ON ua.utility_type = ecftkb.utility_type and ua.units = ecftkb.input_units
			WHERE ss.name = '' #Add scorecard name here
			AND s.portfolio_id IN () #Add portfolio IDs here
			AND ss.valid = 1
			AND ((ua.utility_type IN ('E', 'G', 'P', 'S')) or (ua.utility_type LIKE "%Oil%"))
			AND ua.who_pays IN ('T', 'O', 'C')
			GROUP BY property_scorecard_utility_scorecards_id, utility_type
	  	) AS usage_by_utility
	  ) AS temp
	  GROUP BY temp.site_id
	) as current_emissions
	LEFT JOIN (
	  	SELECT
	  		spaces.site_id,
	  	    SUM(factor_2024 * sqft) AS emissions_cap_2024_mTCo2e,
	  	    SUM(factor_2030 * sqft) AS emissions_cap_2030_mTCo2e
	  	FROM (
			SELECT
				s.parent_space_id AS site_id,
				s.name AS space_name,
  			CASE
  				WHEN s.space_type_enum = 1 THEN 0.00675 -- Multifamily Housing
  				WHEN s.space_type_enum = 3 THEN 0.00846 -- Office
  				WHEN s.space_type_enum = 4 THEN 0.00846 -- Medical Office
  				WHEN s.space_type_enum = 5 THEN 0.01181 -- Retail
  				WHEN s.space_type_enum = 6 THEN 0.00846 -- Bank
  				WHEN s.space_type_enum = 7 THEN 0.01181 -- Supermarket
  				WHEN s.space_type_enum = 8 THEN 0.00426 -- Warehouse Unrefrigerated
  				WHEN s.space_type_enum = 9 THEN 0.01074 -- Court House
  				WHEN s.space_type_enum = 10 THEN 0.00846 -- Data Center
  				WHEN s.space_type_enum = 11 THEN 0.02381 -- Hospital
  				WHEN s.space_type_enum = 12 THEN 0.00987 -- Hotel
  				WHEN s.space_type_enum = 13 THEN 0.01074 -- House Worship
  				WHEN s.space_type_enum = 14 THEN 0.00758 -- School
  				WHEN s.space_type_enum = 15 THEN 0.01074 -- Pool
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Bar/Night Club' THEN 0.01074 -- Other - Bar/Night Club
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'College/University' THEN 0.00846 -- Other - College University
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mall - Enclosed' THEN 0.01181 -- Other - Enclosed Mall
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Energy/Power Station' THEN 0.00574 -- Other - Energy/Power Station
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Fast Food Restaurant' THEN 0.01074 -- Other - Fast Food Restaurant
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Fire Station' THEN 0.00846 -- Other - Fire Station
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Fitness Center' THEN 0.01074 -- Other - Fitness Center
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Food Service' THEN 0.01074 -- Other - Food Service
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Library' THEN 0.00758 -- Other - Library
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mailing Center/Post Office' THEN 0.00846 -- Other - Mailing Center/Post Office
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Movie Theater' THEN 0.01074 -- Other - Movie Theater
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Museum' THEN 0.01074 -- Other - Museum
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Other' THEN 0.00846 -- Other - Other
					WHEN s.space_type_enum = 16 AND dp2.string_value = 'Education - Other' THEN 0.00758 -- Other - Education
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Entertainment/Public Assembly - Other' THEN 0.01074 -- Other - Entertainment/Public Assembly
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Lodging/Residential - Other' THEN 0.00675 -- Other - Lodging/Residential
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Public Services - Other' THEN 0.00846 -- Other - Public Services
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Recreation - Other' THEN 0.01074 -- Other - Recreation
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Restaurant/Bar - Other' THEN 0.01074 -- Other - Restaurant/Bar
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mall - Other' THEN 0.01181 -- Other - Mall - Other
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Services - Other' THEN 0.00846 -- Other - Services
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Hospital (Specialty)' THEN 0.02381 -- Other - Hospital (Specialty)
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Outpatient Rehabilatation/Physical Therapy' THEN 0.00846 -- Other - Outpatient Rehabilatation/Physical Therapy
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Performing Arts' THEN 0.01074 -- Other - Performing Arts
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Personal Services' THEN 0.00846 -- Other - Personal Services
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Police Station' THEN 0.00846 -- Other - Police Station
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Pre-school/Daycare' THEN 0.00758 -- Other - Pre-school/Daycare
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Repair Services (Vehicle, Shoe, Locksmith, etc)' THEN 0.00846 -- Other - Repair Services (Vehicle, Shoe, Locksmith, etc)
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Self Storage Facility' THEN 0.00426 -- Other - Self Storage Facility
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Social/Meeting Hall' THEN 0.01074 -- Other - Social/Meeting Hall
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mall - Strip' THEN 0.01181 -- Other - Mall - Strip
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Urgent Care/Clinic/Other Outpatient' THEN 0.00846 -- Other - Urgent Care/Clinic/Other Outpatient
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Veterinary Office' THEN 0.00846 -- Other - Veterinary Office
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Vocational School' THEN 0.00846 -- Other - Vocational School
  				WHEN s.space_type_enum = 17 THEN 0.00426 -- Parking
  				WHEN s.space_type_enum = 18 THEN 0.01181 -- Food Sales
  				WHEN s.space_type_enum = 19 THEN 0.01181 -- Convenience Store with Gas Station
  				WHEN s.space_type_enum = 20 THEN 0.01138 -- Senior Care
  				WHEN s.space_type_enum = 21 THEN 0.01181 -- Convenience Store without Gas Station
  				WHEN s.space_type_enum = 22 THEN 0.01181 -- Wholesale Club/Supercenter
  				WHEN s.space_type_enum = 23 THEN 0.01074 -- Restaurant
  				WHEN s.space_type_enum = 25 THEN 0.00846 -- Financial Office
  				WHEN s.space_type_enum = 26 THEN 0.01138 -- Residential Care Facility
  				WHEN s.space_type_enum = 81 THEN 0.00426 -- Warehouse Refrigerated
  				WHEN s.space_type_enum = 82 THEN 0.00426 -- Distribution Center
  				WHEN s.space_type_enum = 161 THEN 0.00846 -- College University
  				ELSE 0.00846                              -- Unknown
  			END as factor_2024,
  			CASE
  				WHEN s.space_type_enum = 1 THEN 0.00407 -- Multifamily Housing
  				WHEN s.space_type_enum = 3 THEN 0.00453 -- Office
  				WHEN s.space_type_enum = 4 THEN 0.00453 -- Medical Office
  				WHEN s.space_type_enum = 5 THEN 0.00403 -- Retail
  				WHEN s.space_type_enum = 6 THEN 0.00453 -- Bank
  				WHEN s.space_type_enum = 7 THEN 0.00403 -- Supermarket
  				WHEN s.space_type_enum = 8 THEN 0.00110 -- Warehouse Unrefrigerated
  				WHEN s.space_type_enum = 9 THEN 0.00420 -- Court House
  				WHEN s.space_type_enum = 10 THEN 0.00453 -- Data Center
  				WHEN s.space_type_enum = 11 THEN 0.01330 -- Hospital
  				WHEN s.space_type_enum = 12 THEN 0.00526 -- Hotel
  				WHEN s.space_type_enum = 13 THEN 0.00420 -- House Worship
  				WHEN s.space_type_enum = 14 THEN 0.00344 -- School
  				WHEN s.space_type_enum = 15 THEN 0.00420 -- Pool
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Bar/Night Club' THEN 0.00420 -- Other - Bar/Night Club
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'College/University' THEN 0.00453 -- Other - College University
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mall - Enclosed' THEN 0.00403 -- Other - Enclosed Mall
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Energy/Power Station' THEN 0.00167 -- Other - Energy/Power Station
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Fast Food Restaurant' THEN 0.00420 -- Other - Fast Food Restaurant
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Fire Station' THEN 0.00453 -- Other - Fire Station
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Fitness Center' THEN 0.00420 -- Other - Fitness Center
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Food Service' THEN 0.00420 -- Other - Food Service
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Library' THEN 0.00344 -- Other - Library
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mailing Center/Post Office' THEN 0.00453 -- Other - Mailing Center/Post Office
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Movie Theater' THEN 0.00420 -- Other - Movie Theater
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Museum' THEN 0.00420 -- Other - Museum
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Other' THEN 0.00453 -- Other - Other
					WHEN s.space_type_enum = 16 AND dp2.string_value = 'Education - Other' THEN 0.00344 -- Other - Education
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Entertainment/Public Assembly - Other' THEN 0.00420 -- Other - Entertainment/Public Assembly
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Lodging/Residential - Other' THEN 0.00407 -- Other - Lodging/Residential
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Public Services - Other' THEN 0.00453 -- Other - Public Services
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Recreation - Other' THEN 0.00420 -- Other - Recreation
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Restaurant/Bar - Other' THEN 0.00420 -- Other - Restaurant/Bar
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mall - Other' THEN 0.00403 -- Other - Mall - Other
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Services - Other' THEN 0.00453 -- Other - Services
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Hospital (Specialty)' THEN 0.01330 -- Other - Hospital (Specialty)
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Outpatient Rehabilatation/Physical Therapy' THEN 0.00453 -- Other - Outpatient Rehabilatation/Physical Therapy
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Performing Arts' THEN 0.00420 -- Other - Performing Arts
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Personal Services' THEN 0.00453 -- Other - Personal Services
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Police Station' THEN 0.00453 -- Other - Police Station
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Pre-school/Daycare' THEN 0.00344 -- Other - Pre-school/Daycare
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Repair Services (Vehicle, Shoe, Locksmith, etc)' THEN 0.00453 -- Other - Repair Services (Vehicle, Shoe, Locksmith, etc)
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Self Storage Facility' THEN 0.00110 -- Other - Self Storage Facility
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Social/Meeting Hall' THEN 0.00420 -- Other - Social/Meeting Hall
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Mall - Strip' THEN 0.00403 -- Other - Mall - Strip
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Urgent Care/Clinic/Other Outpatient' THEN 0.00453 -- Other - Urgent Care/Clinic/Other Outpatient
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Veterinary Office' THEN 0.00453 -- Other - Veterinary Office
  				WHEN s.space_type_enum = 16 AND dp2.string_value = 'Vocational School' THEN 0.00453 -- Other - Vocational School
  				WHEN s.space_type_enum = 17 THEN 0.00110 -- Parking
  				WHEN s.space_type_enum = 18 THEN 0.00403 -- Food Sales
  				WHEN s.space_type_enum = 19 THEN 0.00403 -- Convenience Store with Gas Station
  				WHEN s.space_type_enum = 20 THEN 0.00598 -- Senior Care
  				WHEN s.space_type_enum = 21 THEN 0.00403 -- Convenience Store without Gas Station
  				WHEN s.space_type_enum = 22 THEN 0.00403 -- Wholesale Club/Supercenter
  				WHEN s.space_type_enum = 23 THEN 0.00420 -- Restaurant
  				WHEN s.space_type_enum = 25 THEN 0.00453 -- Financial Office
  				WHEN s.space_type_enum = 26 THEN 0.00598 -- Residential Care Facility
  				WHEN s.space_type_enum = 81 THEN 0.00110 -- Warehouse Refrigerated
  				WHEN s.space_type_enum = 82 THEN 0.00110 -- Distribution Center
  				WHEN s.space_type_enum = 161 THEN 0.00453 -- College University
  				ELSE 0.00453                             -- Unknown and R-3
  			END as factor_2030,
				-- in ESC Parking Space is treated as without square footage, that's why we need to take
        -- specific fields values and summarize them to get Sqft
        CASE WHEN s.space_type_enum = 17 THEN (
                select SUM(string_value) from esc_prod_db.dynamic_property dp
                where dp.object_id = s.id and dp.name IN ('spaceEnclosed', 'spaceOpen', 'spaceUnenclosed')
        ) ELSE s.square_feet END AS sqft
			FROM esc_prod_db.space s
			JOIN esc_prod_db.site si on s.parent_space_id = si.id
			JOIN esc_prod_db.view_properties_unfiltered vpu ON vpu.id = si.id AND vpu.billable_status = 'Billable'
  		LEFT JOIN esc_prod_db.dynamic_property dp2
  			ON s.id = dp2.object_id and dp2.name = 'otherType'
			WHERE space_type_enum > 0
			AND si.portfolio_id IN () #Add portfolio IDs here
			GROUP BY s.id
			ORDER BY s.parent_space_id
		) AS spaces
	GROUP BY spaces.site_id
	) AS emissions_caps ON emissions_caps.site_id = current_emissions.site_id
	LEFT JOIN esc_prod_db.site si
	  ON si.id = emissions_caps.site_id
	LEFT JOIN esc_prod_db.site_address sa
	  ON sa.site_id = emissions_caps.site_id
	JOIN esc_prod_db.view_properties_unfiltered vpu ON vpu.id = si.id AND vpu.billable_status = 'Billable'
) alias
ORDER BY alias.`ESC Site Name`
