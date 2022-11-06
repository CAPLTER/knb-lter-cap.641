# knb-lter-cap.641

## dataset publishing: Salt River Biological Project (SRBP) birds

FOR SRBP: there are six birding points at each site, two birding points along
each of the three transects, yielding, for example, Tonto_mid_B1, Tonto_mid_B2
(recall that there are three herp plots along each transect). To this point, a
single birder (formerly Melanie), birded at all six points four times per
year. The other two birders, birded at a single core site during the two
regular birding seasons.

_A note about Flying_. The meaning of 'flying' in the birds table is unclear.
There are 1962 records where flying = 1. All of these except for two records
have distance = FT. However, not all records where distance = FT have a
distance = 1 (or any value). Adding confusion, in her metadata, C. Gries has
listed that flying = NULL is true, but then what would be the meaning of flying
= 0, and that would mean that most birds were flying. My impression is that
flying was a precursor to FT. A "flying" option is not on the current
datasheet, nor on an earlier one revised in 2004. Given that the meaning of
"flying" is not clear nor particularly additive, those data are not included in
the published data.

### knb-lter-cap.641.8 _2022-11-06_

- data refresh
- workflow adjusted to accommodate new workflow in capeml where datatables are
  called from yaml.

### knb-lter-cap.641.7 _2022-01-27_

This version reflects the first to be based on the new database migrated from
MySQL::lter34birds to postgresql::core_birds. Data quality and structure were
greatly improved as part of the migration, which translated into reduced and
more efficient code at this publishing step. Except for the river reach
component, the structure was organized to mirror the details (names,
orgization, etc.) of the core birds data (knb-lter-cap.46).

- unfortunately, even at this time, spring 2019 are still the most recently
  QC'd data
- core_birds that had reflected both survey details and bird observations was
  split into separate bird_observations and bird_surveys data tables
- additional_bird_observations was merged as a single field into bird_surveys
* data limited to most recently QC'd set: 2019-05-03


### knb-lter-cap.641.6 _2020-09-29_

This version is primarily a data refresh to correct an error identified by S.
Wittlinger where the core survey of the SRBP core site conducted independent of
the SRBP survey was being included in the data. This error occurred because the
query was pulling data from all SRBP sites. The problem with that approach is
that the core SRBP site at each reach is visited as part of the core survey.
This is not a problem when the core site at each reach is surveyed as part of
the SRBP survey but it is a problem when the rotation of birders who vist the
single core SRBP site at each reach as part of the larger core sites is
incorporated. The solution is to address this by identifying situations when
more than one SRBP site was visited on a given day. The only potential pitfall
that I can see is if there was ever a case where the birders had to make up one
(and only one!) of the sites on a different day. So, for example, if birder A
birded at five of the six sites on Monday but could not finish and had to
address the sixth site on Tuesday, that sixth site would fall through the
cracks. I do not see in the records that this has ever happened but is
something to note. In fact, protocol states that the six SRBP sites at a given
reach should be conducted on the same day so this should be a non-issue but,
again, one for which to watch. 

The logic to restrict the query to pulling only SRBP data is incorporated into
both the `srbp_birds` and `additional_bird_species` queries.  However, the
query is isolated independently in `SRBP_surveys.R` in this respository for
convenience for spot-checking that the appropriate surveys are being pulled.
One easy check is that the SRBP surveys are conducted by one birder only. This
was M. Banville in early years of the project, and K. Godbeer more recently.
The only exception being 2017 when multiple birders contributed (but in 2017
only).

Observation data were filtered to include up to only fall 2019 (2019-10-26) as
data were QC'd to that point only.

### knb-lter-cap.641.5 _2020-09-05_ 

Observation data were filtered to include up to only fall 2019 (2019-10-26) as
data were QC'd to that point only.

### knb-lter-cap.641.4 _2020-08-20_ 

Observation data were filtered to include up to only spring 2019 (2019-05-03)
as data were QC'd to that point only.

