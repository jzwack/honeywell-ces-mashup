# Honeywell Lyric and City of LV Data Mashup
I made this overnight at the ReadWrite Smart Cities Hackathon at CES 2017.

User signs up with their honeywell account, then picks a solar generating site along with a date.

Then I compare the power generated that selected month to the average for that site for all the available data. If the average is higher than the month selected, the available power is assumed to be lower. We then automatically send a new schedule to the Honeywell T-Series thermostat so the device doesn't cool or heat as ofted according to schedule.

Instructions to run:
 - Have Ruby available
 - You will need the following vaules in the settings block:
   - Honeywell apiKey
   - Honeywell apiSecret
   - OpenData appToken
   - Honeywell redirectUri for Oauth2
   - OpenData soda_domain (in my case it was from City of Las Vegas)

I have it hard coded to my City of LV data source but that along with the soda queries are easily changed to whatever data you wish to compare.

It's not perfect but shows a quick example of how city data could be used to control a smart thermostat for energy saving purposes.