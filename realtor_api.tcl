

#		realtor.ca API
#	Tommy Freethy - September 2019
#
# As of writing this, realtor.ca does not have documentation on their API. Someone made a node.js package 
# that wraps the API, they have some information at: https://github.com/Froren/realtorca
#
# Currently I only use this script to get a list of all detached houses in Aurora, Ontario. 
#
# I would like to use the API to monitor listings in the GTA to try to get a feeling of the overall
# state of the housing market in the area.
#
# Modified for csv output for data collection for school project by Ryan S


package require http
package require tls
package require json

namespace eval realtor_api {
	variable _api_address "https://api37.realtor.ca/Listing.svc/PropertySearch_Post"
	
	proc main {} {
		http::register https 443 [list ::tls::socket -tls1 1]
		test_api
	}
	
	# YYC 
	# LongitudeMin -115.17457 \
	# LongitudeMax -112.99927 \
	# LatitudeMin 50.69620 \
	# LatitudeMax 51.35781 \
	
	# YWG 
	# LongitudeMin -97.69638 \
	# LongitudeMax -96.60874 \
	# LatitudeMin 49.68410 \
	# LatitudeMax 50.02322 \	

	# YEG 
	# LongitudeMin -114.58014 \
	# LongitudeMax -112.40484 \
	# LatitudeMin 53.24254 \
	# LatitudeMax 53.86743 \	
	
	
	
	proc test_api {} {
		# Can only request for one page of listings at a time
		set fp [open "input.txt" w+]
		set CurrentPage 1
		while {1} {
			set Query [::http::formatQuery \
				CultureId 1 \
				ApplicationId 1 \
				PropertySearchTypeId 1 \
				LongitudeMin -114.58014 \
				LongitudeMax -112.40484 \
				LatitudeMin 53.24254 \
				LatitudeMax 53.86743 \
				PriceMin 400000 \
				PriceMax 450000 \
				BuildingTypeId 1 \
				ConstructionStyleId 3 \
				CurrentPage $CurrentPage \
			]
			set Result [realtor_request $Query]
			if {$Result eq ""} {
				break
			}
			set ResultDict [json::json2dict $Result]
			#puts $fp $ResultDict
			#puts $fp [::dict keys $ResultDict]
			set CurrentPage [::dict get $ResultDict "Paging" "CurrentPage"]
			set TotalPages [::dict get $ResultDict "Paging" "TotalPages"]
			
			# puts $fp "---------------------------------------"
			# puts $fp "Result retrieved for page: $CurrentPage"
			# puts $fp "---------------------------------------"
			
			set Listings [::dict get $ResultDict "Results"]
			#puts $fp $Listings
			#puts $fp [::dict keys $Listings]
			foreach Listing $Listings {
			
				#puts $fp $Listing
				#puts $fp [::dict keys $Listing]
				set Id [::dict get $Listing "Id"]
				set MlsNumber [::dict get $Listing "MlsNumber"]
				set Price [::dict get $Listing "Property" "Price"]
				set Bedrooms [::dict get $Listing "Building" "Bedrooms"]
				#set Bathrooms [::dict get $Listing "Building" "BathroomTotal"]
				set SizeInterior [::dict get $Listing "Building" "SizeInterior"]
				set PostalCode [::dict get $Listing "PostalCode"]
				set StatusId [::dict get $Listing "StatusId"]
				set URL [::dict get $Listing "RelativeURLEn"]
				set Building [::dict get $Listing "Building"]
				# puts $fp $MlsNumber
				# puts $fp $Price
				# puts $fp $Building
				
				
				#puts $fp "Bedrooms=$Bedrooms, Bathrooms=$Bathrooms, Price=$Price, Size=$Size, ID=$ID, MlsNumber=$MlsNumber"
				#  ID, MlsNumber, postalcode, Price, StausID, RelativeURLEn 
				puts $fp "$Id, $MlsNumber, $Price, $SizeInterior, $Bedrooms, $PostalCode, $StatusId, $URL"
			}
			if {$CurrentPage == $TotalPages} {
				break
			}
			incr CurrentPage
		}
	}
	
	#Nice and simple request. No cookies, API keys, or authorization. Not even SNI.
	proc realtor_request {Query} {
		variable _api_address
		set fpe [open "errors.txt" w+]
		# puts $fp "realtor_request...sending request to: $URL"
		if {[catch {
			set Token [::http::geturl $_api_address \
				-timeout 10000 \
				-query $Query \
			]
		} error]} {
			puts $fpe "realtor_request...Something went wrong: $error"
			return "";
		}
		
		if {[http::status $Token] eq "timeout"} {
			puts $fpe "realtor_request...timeout"
			http::cleanup $Token
		}
		if {[http::ncode $Token] ne 200} {
			# For debugging. Outputs $fp contents of HTTP header
			foreach {Name Value} [http::meta $Token] {
				puts $fpe "realtor_request...Code not 200, $Name=$Value"
			}
			return ""
		}
		
		set Result [http::data $Token]
		http::cleanup $Token
		return $Result
	}
}

realtor_api::main
