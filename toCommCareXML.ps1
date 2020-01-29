#SCRIPT to turn an ODK xls form into a Commcare XML

# when lookuptable is need the choice in the XLS files should have a leading "lut_" folowed by the same name as the lookup table in almanach
# in ODK, in order to create the instance used in calcualtion a fake select need to be created, those row should have a name starting by "fake_select" and have "name = fake" in the choice filter
# data with a name lead by label_ will have markdown activated
# HTML tag will be transformed into marksdown
# multiple choice with filter requre a hidden field called "lang-code" where the loogup lang property is specified  https://confluence.dimagi.com/display/commcarepublic/Using+Lookup+Tables+with+Multiple+Languages


#. Get the content
$PathToXMLFile =  "data.xml"


# replace <translation lang="Francais (fr)"> and change it to <translation lang="fra"
$regex_lang = '"Fran\wais \(fr\)"'
$replace_lang ='"fra"'
#add vellum def
$regex_vellum = 'xmlns:jr="http://openrosa.org/javarosa"'
$replace_vellum = 'xmlns:jr="http://openrosa.org/javarosa" xmlns:vellum="http://commcarehq.org/xforms/vellum"'
# once 
$regex_once = 'calculate="once\( ?if\( ?/data/(([^"](?!"))+)\)' 
$replace_once ="vellum:calculate=`"if(#form/`$1"
#remove fake select questions
$regex_fake_q_txt = '<text id="(/[^/|^"]+)+/fake_select[^"]+"><value>((.(?!/value>))+)</value></text>'
#remove fake select def 
$regex_fake_q_def = '<fake_select[^>]+>'
#remove fake select bind 
$regex_fake_q_bind = '<bind nodeset="(/[^/|^"]+)+/fake_select[^"]+" relevant="false\(\)" type="select1?"/>'
#remove fake select ooption list because they are defined in the commcare lookuptable
$regex_fake_select = "<select1? ref=`"(/[^/|^`"]+)+/fake_select[^`"]+`"><label ref=`"[^`"]+`"\/><itemset nodeset=`"instance\('\w+'\)/root/item`\[name = fake\]`"><value ref=`"[^`"]+`"/><label ref=`"[^`"]+`"/></itemset></select1?>"
#replace the "lut" instance definition with a link toward Commcare lookup table
$regex_dyn_q_instance = "<instance id=`"lut_([^`"]+)`"><root>(.(?!/root))+</root></instance>"
$replace_dyn_q_instance = '<instance src="jr://fixture/item-list:$1" id="$1" />'
#. remove meta question <meta><instanceID/></meta>
$regex_dyn_q_select = "instance\('lut_([^']+)'\)/root/item"
$replace_dyn_q_select = "instance('`$1')/`$1_list/`$1"
#. replace value  the value on the dyn question
$regex_dyn_q_txt = '<value ref="name"/><label ref="jr:itext\(itextId\)"/>'
$replace_dyn_q_txt = "<value ref=`"value`"/><label ref=`"label`"/>"
# remove regex instanceID
$regex_instanceID = '<meta><instanceID/></meta>'
# remove uuid <bind calculate="concat('uuid:', uuid())" nodeset="/data/meta/instanceID" readonly="true()" type="string"/>  
$regex_uuid_bind = "<bind calculate=`"concat\('uuid:', uuid\(\)\)`" nodeset=`"/data/meta/instanceID`" readonly=`"true\(\)`" type=`"string`"/>"
#replace imagepath
$regex_img = 'jr://images'
$replace_img ='jr://file/commcare/image/help/data'
# remove 
$regex_lut_text = '<text id="static_instance-lut[^"]+"><value>((.(?!/value>))+)</value></text>'
#replace color and html codes
$regex_leading_space = '&lt;(\w+)&gt; *'
$replace_leading_space = "&lt;`$1&gt;"
$regex_following_space = ' *&lt;/(\w+)&gt;'
$replace_following_space = "&lt;/`$1&gt;"
$regex_title = '&lt;h[1-9]&gt; *(([^&](?! {0-10}&))+) *&lt;/h[1-9]&gt;'
$replace_title = "# **`$1**"
$regex_li_s = ' *&lt;li&gt; *'
$replace_li_s = '* '
$regex_li_e = '&lt;/li&gt;'
$regex_ul = '&lt;/?ul&gt;'
$regex_span = '&lt;span[^&]*&gt;([^&]+)&lt;/span&gt;'
$replace_span = "**`$1**"
# enforce markdown
$regex_markdown = '(?s)<text id="((/[^/|^"]+)+/label_[^"]+)"><value>((.(?!/value))+)</value></text>'
$replace_markdown = "<text id=`"`$1`"><value form=`"markdown`">`$3</value></text>"



(Get-Content  -Encoding UTF8 -Path $PathToXMLFile) `
    -replace $regex_lang , $replace_lang `
    -replace $regex_vellum , $replace_vellum `
    -replace $regex_once , $replace_once `
	-replace $regex_fake_q_txt, '' `
	-replace $regex_fake_q_def, '' `
	-replace $regex_fake_q_bind, '' `
	-replace $regex_fake_select, '' `
	-replace $regex_dyn_q_instance, $replace_dyn_q_instance `
	-replace $regex_dyn_q_select, $replace_dyn_q_select `
	-replace $regex_dyn_q_txt, $replace_dyn_q_txt `
	-replace $regex_dyn_text, '' `
	-replace $regex_instanceID, '' `
	-replace $regex_uuid_bind, ''  `
	-replace $regex_lut_text, ''  `
	-replace $regex_leading_space, $replace_leading_space `
	-replace $regex_following_space, $replace_following_space `
	-replace $regex_img, $replace_img `
	-replace $regex_li_e, '' `
	-replace $regex_ul, '' `
	-replace $regex_span, '' `
	-replace $regex_li_s, $replace_li_s `
    -replace $regex_title, $replace_title `
	-replace $regex_markdown, $replace_markdown |
  Out-File -Encoding UTF8 ('out.' + $PathToXMLFile)
  

