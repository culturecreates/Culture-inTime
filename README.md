This project is licensed under the GNU General Public License v3.0

Culture inTime 
=========================

Culture inTime is a playground for agregating and visualizing Performing Arts related metadata from multipe data sources. Culture inTime was first developed during [GLAMhack 2020 and 2021](https://hack.glam.opendata.ch/).

Main features: 
* Anyone with basic SPARQL skills can add their own federated SPARQL queries to load data from linked open data (LOD) sources with SPARQL endpoints such as Wikidata.org, Artsdata.ca and open data sources without SPARQL endpoints such as musicbrainz.org.
* Anyone can create their own Spotlights based on data sources in Culture inTime

Culture inTime continues to put its focus on Performing Arts Productions. Version 2 is running at https://culture-intime.herokuapp.com/

Version 3 is coming in the summer of 2022 with a simplified approach to writing SPARQLs. Stay tuned!

Types of Users
=========================
* Power User: Can create SPARQL queries and Spotlights.
* Spotlight Editor: Creates Spotlights on data without needing SPARQL. 
* Browser: Uses Search functionality and pre-configured Spotlights to peruse data. 

Data Sources
=========================
In the section called Data Sources, users can add their own SPARQL queries of existing linked open data (LOD) sources to Culture inTime. The only prerequisties are:
* Technical expertise in creating SPARQL queries
* Knowledge of the graph you want to query
* Login credentials (open to all) 

Two types of SPARQL queries can be added to Culture inTime
* Queries to generate a list of URIs. These URIs are then loaded individually using content negitiation.
* Queries to add supplementary data that augments loaded data. 
To learn more about how to add queries, see the Technical Guide.

To see what's been added, go to https://culture-intime.herokuapp.com/data_sources.

Spotlights
=========================
Spotlights group together productions around a theme. They can span time, locations and data sources. Once you create a login, creating spotlights is easy with a new form that allows Spotlight Editors to choose their parameters and then share their spotlight with the community, or more advanced Spotlights can be created with SPARQL. To see some Spotlights, go to https://culture-intime.herokuapp.com/spotlights.

![Spotlight Page](https://raw.githubusercontent.com/saumier/GLAMhack2020-Culture-inTime/master/images/Spotlight.png)

Technical Guide
========================
To add Spolights or a new data source using SPARQL, please consult this [Google Doc](https://docs.google.com/document/d/1ht17HeUmt-TXJIk139XP4usTn1AV5boWFoSmFw53q-w/edit?usp=sharing) 

GLAMHACK 2020
=========================
The 2020 GlamHack Challenge resulted from the discussions we had earlier in the week during the workshops related to performing arts data and our goal is to create a Linked Open Data Ecosystem for the Performing Arts.

Some of us have been working on this for years, focusing mostly on data cleansing and data publication.
Now, the time has come to shift our focus towards creating concrete applications that consume data from different sources.
This will allow us to demonstrate the power of linked data and to start providing value to users.
At the same time, it will allow us to tackle issues related to data modelling and data federation based on concrete use cases.

“Culture InTime” is one such application. It is a kind of universal cultural calendar, which allows us to put the Spotlight on areas and timespans where coherent sets of data have already been published as linked data. At the same time, the app fetches data from living data sources on the fly. And as more performing arts data is being added to these data sources, they will automatically show up.
It can:
- Provide a robust listing of arts and cultural events, both historical and current. Audiences are able to search for things they are interested in, learn more about performing arts productions and events, find new interests, et cetera.
- Reduce duplication of work in area of data entry

The code is a simple as possible to demonstrate the potential of using LOD (structured data) to create a calendar for arts and cultural events that is generated from data in Wikidata and the [Artsdata.ca](http://artsdata.ca) knowledge graph. 

The user interface is designed to allow visitors to search for events. They can:
- Use the Spotlight feature to quickly view events grouped by theme.
- Use Time Period buttons to search a time period.
- Use a Search field to enter a search using the following criteria: name of production, theatre, city, or country.
- Visit the source of the data to learn more (in the example of an Artsdata.ca event, Click Visit Event Webpage to be redirected to the Arts Organization website.

Note: Currently when you enter a location, data only exists for Switzerland and Canada (country), Zurich, Montreal/Laval/Toronto/Vancouver/Fredericton and some small villages in Quebec.  

Search results list events sorted by date.


Challenges
=========================
Data is modelled differently in Wikidata, Artsdata, and even between projects within the same database.
Data has very few images.

More UI Images
=========================
Spotlight Page

![Spotlight Page](https://raw.githubusercontent.com/saumier/GLAMhack2020-Culture-inTime/master/images/Spotlight.png)

Event Details page - Montreal

![Production Details](https://raw.githubusercontent.com/saumier/GLAMhack2020-Culture-inTime/master/images/ProductionDetails.png)

Production Details page - Zurich

![Production Details](https://raw.githubusercontent.com/saumier/GLAMhack2020-Culture-inTime/master/images/ProductionDetails-Schauspielhaus-Zurich.png)
