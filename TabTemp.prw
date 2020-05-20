#include "totvs.ch"
//------------------------------------------------------------------------------
/*/{Protheus.doc} TabTemp
Criando uma tabela temporária usando a classe FWTemporaryTable

@author 	Dirlei Friedrich

@return 	Nil, nenhum

@see        https://tdn.totvs.com/display/framework/FWTemporaryTable
@type 		function
/*/
//------------------------------------------------------------------------------
User Function TabTemp()

Local aArea      := GetArea()
Local aBrowse    := {}
Local aStruTmp   := {} 
Local oTempTable := Nil
Local cAliasZZ1  := GetNextAlias()
Local cSelect    := ""
Local cFrom      := "% RetSqlName('ZZ1') ZZ1 %"
Local cWhere     := ""  
Local cOrderBy   := "% ZZ1_FILIAL, ZZ1_SERIE, ZZ1_DOC %"
Local lInverte   := .F.
Local oMarkDoc   := Nil

Private cMarca := GetMark()
Private oDlg   := Nil

// Define campos do MsSelect
AAdd(aBrowse,{"OK"       ,,""})  			
AAdd(aBrowse,{"SERIE"    ,,"Série"})
AAdd(aBrowse,{"DOCUMENTO",,"Documento"})
AAdd(aBrowse,{"FORNEC"   ,,"Fornecedor"})
AAdd(aBrowse,{"LOJA"     ,,"Loja"})
AAdd(aBrowse,{"NOME"     ,,"Nome"})
AAdd(aBrowse,{"EMISSAO"  ,,"Emissão"})
AAdd(aBrowse,{"CHAVE"    ,,"Chave"})

// Define campos tabela temporária
AAdd(aStruTmp,{"OK" 	  ,"C",02,0})
AAdd(aStruTmp,{"SERIE" 	  ,"C",TamSX3("F1_SERIE")[1]  ,TamSX3("F1_SERIE")[2]})
AAdd(aStruTmp,{"DOCUMENTO","C",TamSX3("F1_DOC")[1]    ,TamSX3("F1_DOC")[2]})
AAdd(aStruTmp,{"FORNEC"   ,"C",TamSX3("F1_FORNECE")[1],TamSX3("F1_FORNECE")[2]})
AAdd(aStruTmp,{"LOJA"     ,"C",TamSX3("F1_LOJA")[1]   ,TamSX3("F1_LOJA")[2]})
AAdd(aStruTmp,{"NOME"     ,"C",TamSX3("A2_NOME")[1]   ,TamSX3("A2_NOME")[2]})
AAdd(aStruTmp,{"EMISSAO"  ,"D",TamSX3("F1_EMISSAO")[1],TamSX3("F1_EMISSAO")[2]})
AAdd(aStruTmp,{"CHAVE"    ,"C",TamSX3("F1_CHVNFE")[1] ,TamSX3("F1_CHVNFE")[2]})

oTempTable := FWTemporaryTable():New()
oTemptable:SetFields(aStruTmp)
oTempTable:AddIndex('indice1',{'SERIE','DOCUMENTO'})
oTempTable:Create()

//Pego o alias da tabela temporária
cTmpMrk := oTempTable:GetAlias()

// Query
cSelect += "%"
cSelect += " ZZ1.ZZ1_FORNEC AS FORNEC,"
cSelect += " ZZ1.ZZ1_LOJA AS LOJA,"
cSelect += " ZZ1.ZZ1_NOME AS NOME,"
cSelect += " ZZ1.ZZ1_SERIE AS SERIE,"
cSelect += " ZZ1.ZZ1_DOC AS DOC,"
cSelect += " ZZ1.ZZ1_EMISSA AS EMISSAO,"
cSelect += " ZZ1.ZZ1_CHAVE AS CHAVE"
cSelect += "%"

cWhere += "%"
cWhere += " ZZ1.ZZ1_FORNEC = '"+ MV_PAR01 +"'
cWhere += " AND ZZ1.ZZ1_LOJA = '"+ MV_PAR02 +"'
cWhere += " AND ZZ1.ZZ1_EMISSA BETWEEN '"+ DtoS(MV_PAR03) +"' AND '"+ DtoS(MV_PAR04) +"'"
cWhere += " AND ZZ1.D_E_L_E_T_ != '*'"
cWhere += "%"

BeginSql Alias cAliasZ1Z
	SELECT %Exp:cSelect%
	FROM   %Exp:cFrom%
	WHERE  %Exp:cWhere%
	ORDER BY %Exp:cOrderBy%
EndSql
// Mostra query
//Aviso("",GetLastQuery()[2],{"Ok"},3,,,,.T.)

dbSelectArea(cAliasZZ1)
(cAliasZZ1)->(dbGoTop())
While !(cAliasZZ1)->(Eof())
		
	RecLock(cTmpMrk,.T.)
		
	(cTmpMrk)->OK 		 := Space(2)
	(cTmpMrk)->SERIE	 := (cAliasZZ1)->SERIE
	(cTmpMrk)->DOCUMENTO := (cAliasZZ1)->DOC
	(cTmpMrk)->FORNEC	 := (cAliasZZ1)->FORNEC
	(cTmpMrk)->LOJA      := (cAliasZZ1)->LOJA
	(cTmpMrk)->NOME      := (cAliasZZ1)->NOME
	(cTmpMrk)->EMISSAO   := StoD((cAliasZZ1)->EMISSAO)
	(cTmpMrk)->CHAVE     := (cAliasZZ1)->CHAVE
	
	(cTmpMrk)->(MsUnlock())
		
	(cAliasZZ1)->(dbSkip())
		
EndDo

// Tela de marcação 
Define MSDialog oDlg Title "Seleção de Documentos" From 000, 000 to 400, 600 Colors 0, 16777215 Pixel

SButton():New(175,225,02,{|| nOpcx:=0,oDlg:End()},oDlg,.T.,,) // Cancelar
SButton():New(175,255,01,{|| nOpcx:=1,oDlg:End()},oDlg,.T.,,) // Ok

oMarkDoc := MsSelect():New(cTmpMrk,'OK','',aBrowse,@lInverte,cMarca,{015,005,170,300})
oMarkDoc:oBrowse:lCanAllMark := .T.
oMarkDoc:oBrowse:lHasMark    := .T.
oMarkDoc:bAval               := { || fMarkDoc(1),oMarkDoc:oBrowse:Refresh(.T.)}
oMarkDoc:oBrowse:bAllMark    := { || fMarkDoc(2),oMarkDoc:oBrowse:Refresh(.T.)}
oMarkDoc:oBrowse:Align       := CONTROL_ALIGN_NONE

Eval(oMarkDoc:oBrowse:bGoTop)
oMarkDoc:oBrowse:Refresh()

Activate MSDialog oDlg Centered

If nOpcx == 1

	// Processamento ....

EndIf

If Select(cTmpMrk) > 0
	dbSelectArea(cTmpMrk)
	(cTmpMrk)->(dbCloseArea())
EndIf

Return .T.


//---------------------------------------------------------------------
/*/{Protheus.doc} fMarkDoc
Rotina para marcar registros

@author		Dirlei@afsouza

@param		nOpc, numerico, Opção da marcação
@return 	Nil, nenhum

@type 		function
/*/
//---------------------------------------------------------------------
Static Function fMarkDoc(nOpc)

If nOpc == 1

	RecLock(cTmpMrk,.F.) 
	If !IsMark('OK',cMarca)
		(cTmpMrk)->OK := cMarca
	Else
		(cTmpMrk)->OK := Space(Len((cTmpMrk)->OK))
	EndIf
	MsUnlock(cTmpMrk)

Else

	(cTmpMrk)->(dbGoTop())
	While !(cTmpMrk)->(Eof())
		RecLock((cTmpMrk),.F.)
		If !IsMark('OK',cMarca)
			(cTmpMrk)->OK := cMarca
		Else
			(cTmpMrk)->OK := Space(Len((cTmpMrk)->OK))
		EndIf
		MsUnlock((cTmpMrk))
		(cTmpMrk)->(dbSkip())
	EndDo
EndIf

oDlg:Refresh(.T.)

Return Nil
