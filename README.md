# XLSForm to CommCare
Script to adapt XLSForm output XML to an XML compatible with CommCare
Done in the scope of the SysRef project funded by the Stanley Thomas Johnson Foundation

## How to build the XLSForm to be compatible


### Look up table.

In CommCareHQ, lookup table can be used to filter data, but it also possible in XLSFrom, the trick is the create "instance" of the choice list by using a fake select_one but in CommCare this fake select is useless therefore we need to remove it. To do so the fake select need to comply with those constraints
* name starting by "fake_select" 
* Haveve "name = fake" in the choice filter

Also in Commcare we need to map the instance to a lookup table, to do so:
* in XLSForm the choice list that should be lookup table in CommCareHQ need start with lut_" followed by the same name as the lookup table in CommCareHQ
### Conditionnal multiple choice

in CommCareHQ the Conditionnal multiple choice need to use a lookup table, follow CammCare instruction build such lookup table, by default the script will use the column called "value" for the value and label for the label (this field can be in several languages)

### Calculation of the default Value

To Calculate a default value, use the once(if(...)) functions, those will be adapted to match CommCareHQ fields 

### Presentation.

 To enable markdowns (create title ... ), the name of the note needs to start with "label_"
 
 HTML tag (h1, h2 ,li... ) will be transformed in markdowns
 

## Steps to follow

1. Use Excel to create your questionnaire, name the file data.xls (important for CommCareHQ, the script might support other name later)
2. With XLSForm online or offline create the data.xml
3. execute the script in the same folder as data.xml
4. copy paste the content for out.data.xml in CommcareHQ
5. Ensure that CommCare HQ has all pictures and required a lookup table
6. then you can create a new application version


