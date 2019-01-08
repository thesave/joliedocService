/********************************************************************************
 *   Copyright (C) 2019 by Saverio Giallorenzo <saverio.giallorenzo@gmail.com>  *
 *                                                                              *
 *   This program is free software; you can redistribute it and/or modify       *
 *   it under the terms of the GNU Library General Public License as            *
 *   published by the Free Software Foundation; either version 2 of the         *
 *   License, or (at your option) any later version.                            *
 *                                                                              *
 *   This program is distributed in the hope that it will be useful,            *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
 *   GNU General Public License for more details.                               *
 *                                                                              *
 *   You should have received a copy of the GNU Library General Public          *
 *   License along with this program; if not, write to the                      *
 *   Free Software Foundation, Inc.,                                            *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                  *
 *                                                                              *
 *   For details about the authors of this software, see the AUTHORS file.      *
 ********************************************************************************/

include "types/IOException.iol"

type JolieDocRequest: void {
  .file: string
  .includes*: string
  .libraries*: string
}

type TypeInfoType: void {
  .name: string
  .code: string
  .isNative: bool
  .documentation?: string
}

type FaultInfoType: void {
  .name: string
  .faultType: TypeInfoType
}

type OperationInfoType: void {
  .name: string
  .requestType: TypeInfoType
  .responseType?: TypeInfoType
  .fault*: FaultInfoType
  .documentation?: string
}

type InterfaceInfoType: void {
  .name: string
  .operation*: OperationInfoType
  .documentation?: string
}

type PortInfoType : void {
  .name: string
  .location?: string
  .protocol?: string
  .interface*: InterfaceInfoType
  .isOutput: bool
  .documentation?: string
  .subtype*: TypeInfoType
}

type ProgramInfoType: void {
  .port*: PortInfoType
  .filename: string
}

interface JolieDocInterface {
  RequestResponse: getDocumentation( JolieDocRequest )( ProgramInfoType )
}

outputPort JolieDoc {
	Interfaces: JolieDocInterface
}

embedded {
Java:
	"joliex.docs.JolieDocService" in JolieDoc
}