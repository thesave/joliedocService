/*******************************************************************************
 *   Copyright (C) 2019 by Saverio Giallorenzo <saverio.giallorenzo@gmail.com> *
 *                                                                             *
 *   This program is free software; you can redistribute it and/or modify      *
 *   it under the terms of the GNU Library General Public License as           *
 *   published by the Free Software Foundation; either version 2 of the        *
 *   License, or (at your option) any later version.                           *
 *                                                                             *
 *   This program is distributed in the hope that it will be useful,           *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 *   GNU General Public License for more details.                              *
 *                                                                             *
 *   You should have received a copy of the GNU Library General Public         *
 *   License along with this program; if not, write to the                     *
 *   Free Software Foundation, Inc.,                                           *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                 *
 *                                                                             *
 *   For details about the authors of this software, see the AUTHORS file.     *
 *******************************************************************************/

include "console.iol"
include "string_utils.iol"
include "file.iol"
include "time.iol"
include "zip_utils.iol"

constants {
  github_address = "socket://github.com:443"
}

outputPort GITHUB {
  Location: github_address
  Protocol: https {
    .osc.get.alias = "%!{page}";
    .responseHeaders = "rh";
    .ssl.protocol = "TLSv1.2";
    .method = "GET"
  }
  RequestResponse: get
}

define resetPort {
  GITHUB.location = github_address
}

main
{
  readFile@File( { .filename = "dependencies.json", .format = "json" } )( dependencies );
  download.format = "binary";
  for ( dependency in dependencies._ ) {
    download.filename = dependency.filename;
    get@GITHUB( { .page = dependency.repository + "/releases/latest" } )( response );
    with( response.rh ) {
      if ( is_defined( .location ) ){
        replaceFirst@StringUtils( .location { .regex = "https://github.com/", .replacement = "" } )( .location );
        replaceFirst@StringUtils( .location { .regex = "tag", .replacement = "download" } )( .location );
        archive.page = .location + "/" + download.filename;
        println@Console( "Downloading " + "https://github.com/" + archive.page )();
        get@GITHUB( archive )( response );
        if( is_defined( .location ) ){
          replaceFirst@StringUtils( .location { .regex = "https://(.+?)/.+", .replacement = "socket://$1:443" } )( GITHUB.location );
          replaceFirst@StringUtils( .location { .regex = "https://(.+?)/", .replacement = "" } )( archive.page );
          { get@GITHUB( archive )( download.content ) | startPrintDots@PrintDots() }; stopPrintDots@PrintDots();
          writeFile@File( download )();
          println@Console( "Unzipping " + download.filename )();
          unzip@ZipUtils( { .filename = download.filename, .targetPath = "." } )();
          println@Console( "Deleting " + download.filename )();
          delete@File( download.filename )();
          resetPort
        }
      } else {
      println@Console( "Could not find the latests version of " + download.filename + 
        ", please download it manually from https://github.com/" + dependency.repository + "/releases/latest" )()
      }
    }
  }
}

interface PrintDotsInterface {
  OneWay: startPrintDots, printDots, stopPrintDots
  RequestResponse: checkForStop
}

service PrintDots 
{
  Interfaces: PrintDotsInterface
  main 
  {
    [ startPrintDots() ]{ print@Console( "[" )(); printDots@PrintDots() }
    [ printDots() ]{ print@Console( "." )(); sleep@Time( 250 )(); 
      checkForStop@PrintDots()( stop ); if ( !stop ){ printDots@PrintDots() } 
      else { undef( global.stop ) } }
    [ checkForStop()( global.stop ) ]
    [ stopPrintDots() ]{ global.stop = true; println@Console( "]" )() }
  }
}