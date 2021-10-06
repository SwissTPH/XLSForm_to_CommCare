#SCRIPT to turn an ODK xls form into a Commcare XML
# the xls must respect this naming convention "_[the name you want]_data.xls" e.i _ecda_data.xls
# when lookuptable is need the choice in the XLS files should have a leading "lut_" folowed by the same name as the lookup table in almanach
# in ODK, in order to create the instance used in calcualtion a fake select need to be created, those row should have a name starting by "fake_select" and have "name = fake" in the choice filter
# data with a name lead by label_ will have markdown activated
# HTML tag will be transformed into marksdown
# multiple choice with filter requre a hidden field called "lang-code" where the loogup lang property is specified  https://confluence.dimagi.com/display/commcarepublic/Using+Lookup+Tables+with+Multiple+Languages

Get-ChildItem  _*_data.xml |`
Foreach-Object {
	
	
	#. Get the content
    $regex_data_look = $_.FullName -match '(\w+).xml'
	if ($regex_data_look) {
		# manage the Breathin app link -replace $regex_breathing_intent, $replace_breathing_intent `
		# -replace $regex_breathing, $replace_breathing `
		# -replace $regex_breathing_bind, $replace_breathing_bind `
		#FIX ME should be same name
		if ((Get-Content  -Encoding UTF8 -Path $_.FullName) -like '*org.commcare.respiratory.BREATHCOUNT*'){
			$regex_breathing_intent = "</h:head>"
			$regex_breathing='intent="org.commcare.respiratory.BREATHCOUNT"'
			$regex_breathing_bind='(bind nodeset="/(?:[^/|^"]+/)+[^"]*breathing_count[^"]*" +(relevant="[^"]+")? +type=")int'
			#<bind vellum:nodeset="#form/g_patient/rtzrtzr" nodeset="/data/g_patient/rtzrtzr" type="intent" />
		}else{
			$regex_breathing_intent = "§§§§§§§§§§"
			$regex_breathing = "§§§§§§§§§§"
			$regex_breathing_bind= "§§§§§§§§§§"
		}
		$replace_breathing_intent = '<odkx:intent xmlns:odkx="http://opendatakit.org/xforms" id="s_breathing_count" class="org.commcare.respiratory.BREATHCOUNT" /></h:head>'
		$replace_breathing = 'intent="s_breathing_count"'
		$replace_breathing_bind= "`$1intent"
		#FIXME<odkx:intent xmlns:odkx="http://opendatakit.org/xforms" id="breathing_count" class="org.commcare.respiratory.BREATHCOUNT" />
		$fileName = $matches[1]
		#in commcare the root must be named data
		$regex_data = "$($fileName)"
		$replace_data = 'data'

		
		# replace <translation lang="Francais (fr)"> and change it to <translation lang="fra"
		$regex_lang = '<translation (default="true\(\)" )?lang="\w+ \((\w+)\)">'
		$replace_lang ='<translation $1lang="$2">'
		$regex_lang2 = '<translation (default="true\(\)" )?lang="fr">'
		$replace_lang2 = '<translation $1lang="fra">'
		$regex_lang3 = '<translation (default="true\(\)" )?lang="hausa">'
		$replace_lang3 = '<translation $1lang="hau">'
		#add vellum def
		$regex_vellum = 'xmlns:jr="http://openrosa.org/javarosa"'
		$replace_vellum = 'xmlns:jr="http://openrosa.org/javarosa" xmlns:vellum="http://commcarehq.org/xforms/vellum"'
		#-replace $regex_vellum_fct, $replace_vellum_fct `
		$regex_vellum_fct = ' (relevant|nodeset)="'
		$replace_vellum_fct = ' vellum:$1="'
		#remove string type for readonly -replace $regex_label, $replace_label `
		$regex_label = 'bind (nodeset="(/(?:[^/|^"]+/)+(?:label|tt)[^"]+)" +readonly="true\(\)"( relevant="[^"]+" )?) type="string"' #
		$replace_label ="bind `$1"
		# help
		$regex_help = "(</\w+>)<input ref=`"[^`"]+?/_help_[^`"]+`"><label (ref=`"[^`"]+`"/>)</input>" #"
		$replace_help = '<help $2$1'
		$regex_help_instance = '<_help_[^/]+/>'
		$regex_help_bind = '<bind nodeset="[^`"]+?/_help_[^`"]+"[^>]+/>'
		# once
		$regex_once = 'calculate="once\( ?if\( ?/data/(([^"](?!"))+)\)' 
		$replace_once ="vellum:calculate=`"if(#form/`$1"
		#remove case select questions
		$regex_case_q_txt = '<text id="(/[^/|^"]+)+/_case_[^"]+"><value>((.(?!/value>))+)</value></text>'
		#remove case select def 
		$regex_case_q_def = '<_case_[^>]+>([^<]*</_case_[^>]+>)?'
		#remove case select bind might not be required
		$regex_case_q_bind = '<bind nodeset="((?:/(?!_case_)(?:[^/|"|>]+))+)/_case_[^"]+" (.(?!>))+/>'
		#remove fake case input
		$regex_case_input = '<input ref="((/[^/|\)|''|"|,|>]+)+)/_case_[^"]+"><label ref="[^"]+"\/></input>'
		#replace the reference to the case
		$regex_case = '<output value=" *((?:/(?!_case_)(?:[^/|"|>]+))+)/_case_([^"]+) *"/>'
		$replace_case = '<output value="instance(''casedb'')/casedb/case[@case_id = instance(''commcaresession'')/session/data/case_id]/$2" vellum:value="#case/$2" />'
		#replace case in calculation
		$regex_case_calc = '((?:/(?!_case_)(?:[^/\)''",> =&]+))+)/_case_([^/\)''",> =&]+)'
		$replace_case_calc = '#case/$2'
		#remove fake select questions
		$regex_fake_q_txt = '<text id="(/[^/|^"]+)+/fake_select[^"]+"><value>((.(?!/value>))+)</value></text>'
		#remove fake select def 
		$regex_fake_q_def = '<fake_select[^>]+>'
		#remove fake select bind 
		$regex_fake_q_bind = '<bind nodeset="(/[^/|^"]+)+/fake_select[^"]+" relevant="false\(\)" type="select1?"/>'
		#remove fake select ooption list because they are defined in the commcare lookuptable
		$regex_fake_select = '<select1? ref="(/[^/|^"]+)+/fake_select[^"]+"><label ref="[^"]+"\/><itemset nodeset="instance\(''\w+''\)/root/item\[name *= *fake\]"><value ref="[^"]+"/><label ref="[^"]+"/></itemset></select1?>'
		#replace the "lut" instance definition with a link toward Commcare lookup table
		$regex_dyn_q_instance = '<instance id="lut_([^"]+)"><root>(.(?!/root))+</root></instance>'
		$replace_dyn_q_instance = '<instance src="jr://fixture/item-list:$1" id="$1" />'
		# Insert location and sessions
		$regex_ext_location = '<instance id="locations"><root>(.(?!/root))+</root></instance>'
		$replace_ext_location = '<instance src="jr://fixture/locations" id="locations" />'
		$regex_ext_ccsession = '<instance id="commcaresession"><root>(.(?!/root))+</root></instance>'
		$replace_ext_ccsession = '<instance src="jr://instance/session" id="commcaresession" />'
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
		$regex_lut_text = '<text id="static_instance-(?:lut¦locations|commcaresession)[^"]*"><value>((.(?!/value>))+)</value></text>'
		#replace color and html codes
		$regex_leading_space = '&lt;(\w+)&gt; *'
		$replace_leading_space = "&lt;`$1&gt;"
		$regex_following_space = ' *&lt;/(\w+)&gt;'
		$replace_following_space = "&lt;/`$1&gt;"
		$regex_title1 = '&lt;h1&gt; *((.(?!lt;/h))+) *&lt;/h1&gt;'
		$replace_title1 = "# **`$1**"
		$regex_title2 = '&lt;h2&gt; *((.(?!lt;/h))+) *&lt;/h2&gt;'
		$replace_title2 = "## **`$1**"
		$regex_title3 = '&lt;h3&gt; *((.(?!lt;/h))+) *&lt;/h3&gt;'
		$replace_title3 = "### `$1"
		$regex_title4 = '&lt;h[4-9]&gt; *((.(?!lt;/h))+) *&lt;/h[4-9]&gt;'
		$replace_title4 = "**`$1**"
		# Bold -replace $regex_bold, $replace_bold `
		$regex_bold = '&lt;b&gt; *((.(?!lt;/b))+) *&lt;/b&gt;'
		$replace_bold = "**`$1**"
		# remove underline only in hint -replace $regex_underline_hint, $replace_underline_hint `
		$regex_underline_hint = '(?ms)hint"><value>((?:.(?!</value))*)?&lt;u&gt;([^&]+?)&lt;/u&gt;'
		$replace_underline_hint = 'hint"><value> $1 $2'
		# remove underline only in hint -replace $regex_underline, $replace_underline `
		$regex_underline = '&lt;u&gt; *([^&]+?) *&lt;/u&gt;'
		$replace_underline = '***$1***'
		# Italic -replace $regex_italic, $replace_italic `
		$regex_italic = '&lt;i&gt; *(.+?) *&lt;/i&gt;'
		$replace_italic = "*$1*"
		$regex_li_s = ' *&lt;li&gt; *'
		$replace_li_s = '* '
		$regex_li_e = '&lt;/li&gt;'
		$regex_ul = '&lt;/?ul&gt;'
		$regex_span = '&lt;span[^&]*&gt;([^&]+)&lt;/span&gt;'
		$replace_span = "**`$1**"
		# enforce markdown 			-replace $regex_markdown, $replace_markdown `
		$regex_markdown = '(?ms)<text id="((/[^/|^"]+)+/[^"]+?label)">(<value form="image">[^<]+</value>)*<value>'
		$replace_markdown = '<text id="$1">$3<value form="markdown">'
		# decimal
		$regex_dec = 'type="decimal"'
		$replace_dec = 'type="xsd:double"'
		# trigger (commcare label) -replace $regex_trigger, $replace_trigger `
		$regex_trigger = '<input ref="(/(?:[^/|^"]+/)+(?:label|tt)[^"]+)"><label ref="([^"]+)"/>(<hint ref="(?:[^"]+)"/>)?(<help ref="(?:[^"]+)"/>)?</input>'
		$replace_trigger = '<trigger ref="$1" appearance="minimal"><label ref="$2"/>$3$4</trigger>'
	# remove the decimal-date-time which is not supported and not required in Commcare
		$regex_decimal_date_time = 'decimal-date-time'
		Write-output "file $($_.FullName) was found"
		(Get-Content  -Encoding UTF8 -Path $_.FullName -Raw ) `
			-replace $regex_underline_hint, $replace_underline_hint `
			-replace $regex_underline, $replace_underline `
			-replace $regex_underline, $replace_underline `
			-replace $regex_underline, $replace_underline `
			-replace $regex_data , $replace_data `
			-replace $regex_lang , $replace_lang `
			-replace $regex_lang2 , $replace_lang2 `
			-replace $regex_lang3 , $replace_lang3 `
			-replace $regex_label, $replace_label `
			-replace $regex_vellum , $replace_vellum `
			-replace $regex_once , $replace_once `
			-replace $regex_decimal_date_time , '' `
			-replace $regex_case_q_txt, '' `
			-replace $regex_case_q_def, '' `
			-replace $regex_case_q_bind, '' `
			-replace $regex_case_input, '' `
			-replace $regex_case_calc, $replace_case_calc `
			-replace $regex_case, $replace_case `
			-replace $regex_fake_q_txt, '' `
			-replace $regex_fake_q_def, '' `
			-replace $regex_fake_q_bind, '' `
			-replace $regex_fake_select, '' `
			-replace $regex_ext_location, $replace_ext_location `
			-replace $regex_ext_ccsession, $replace_ext_ccsession `
			-replace $regex_dyn_q_instance, $replace_dyn_q_instance `
			-replace $regex_dyn_q_select, $replace_dyn_q_select `
			-replace $regex_dyn_q_txt, $replace_dyn_q_txt `
			-replace $regex_dyn_text, '' `
			-replace $regex_instanceID, '' `
			-replace $regex_uuid_bind, ''  `
			-replace $regex_lut_text, ''  `
			-replace $regex_help,$replace_help `
			-replace $regex_help_instance,'' `
			-replace $regex_help_bind,'' `
			-replace $regex_leading_space, $replace_leading_space `
			-replace $regex_following_space, $replace_following_space `
			-replace $regex_img, $replace_img `
			-replace $regex_dec, $replace_dec `
			-replace $regex_markdown, $replace_markdown `
			-replace $regex_li_e, '' `
			-replace $regex_ul, '' `
			-replace $regex_span, $replace_span `
			-replace $regex_li_s, $replace_li_s `
			-replace $regex_title1, $replace_title1 `
			-replace $regex_title2, $replace_title2 `
			-replace $regex_title3, $replace_title3 `
			-replace $regex_title4, $replace_title4 `
			-replace $regex_bold, $replace_bold `
			-replace $regex_italic, $replace_italic `
			-replace $regex_breathing_intent, $replace_breathing_intent `
			-replace $regex_breathing, $replace_breathing `
			-replace $regex_breathing_bind, $replace_breathing_bind `
			-replace $regex_trigger, $replace_trigger `
			-replace $regex_vellum_fct, $replace_vellum_fct `
			| Out-File -Encoding UTF8 ('out.' + $fileName + '.xml')
			
	}
 }
