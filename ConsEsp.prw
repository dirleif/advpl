#Include 'protheus.ch'
#Include 'fwbrowse.ch'
//------------------------------------------------------------------------------
/*/{Protheus.doc} ZC5F3SX3
Consulta especí­fica para tabelas cadastradas na ZC5

@author		Dirlei@afsouza
@since 		18/05/2020
@version	P12

@return 	lRet, lógico

@see		https://centraldeatendimento.totvs.com/hc/pt-br/articles/360015715472-MP-ADVPL-Consulta-Especifica-com-filtro-Customizado-
			https://tdn.totvs.com/display/framework/OpenSxs

@type 		function
/*/
//------------------------------------------------------------------------------
User Function ZC5F3SX3()

Local aArea      := GetArea()
Local lRet       := .F.
Local cFiltro    := ""
Local aHeader    := oGetDados:aHeader
Local aCols      := oGetDados:aCols
Local nLinha     := oGetDados:nAt
Local nPosAlias  := AScan(aHeader,{|x|AllTrim(x[2]) == "ZC5_TABELA"})
Local cTabela    := aCols[nLinha][nPosAlias]
Local oDlg
Local oBrowse
Local oMainPanel
Local oPanelBtn
Local oBtnOK
Local oBtnCan
Local oColumn1
Local oColumn2
Local oColumn3

// Verifica se campo existe
If !Empty(cTabela)
	cFiltro := "ZC5SX3->X3_CONTEXT != 'V' .And. ZC5SX3->X3_TIPO == 'C' .And. ZC5SX3->X3_ARQUIVO == '"+ AllTrim(cTabela) +"'"
EndIf

// Abre dicionário
If Select("ZC5SX3") == 0
	OpenSxs(,,,,cEmpAnt,"ZC5SX3","SX3",,.F.)
EndIf

Define MsDialog oDlg From 000, 000 To 390, 515 Title "Consulta Padrão - Campos do Sistema" Pixel Of oMainWnd		

	@000, 000 MsPanel oMainPanel Size 250, 080
	oMainPanel:Align := CONTROL_ALIGN_ALLCLIENT

	@000, 000 MsPanel oPanelBtn Size 250, 015
	oPanelBtn:Align := CONTROL_ALIGN_BOTTOM

	Define FWBrowse oBrowse DATA TABLE ALIAS "ZC5SX3" NO CONFIG NO REPORT DOUBLECLICK { || lRet := .T.,  oDlg:End() } Of oMainPanel
	Add Column oColumn1  DATA { || ZC5SX3->X3_CAMPO }  Title "Campo" Size Len(ZC5SX3->X3_CAMPO) Of oBrowse
	Add Column oColumn2  DATA { || If(__LANGUAGE == "SPANISH",ZC5SX3->X3_TITSPA,If(__LANGUAGE == "ENGLISH",ZC5SX3->X3_TITENG,ZC5SX3->X3_TITULO)) } Title "Titulo" Size Len(ZC5SX3->X3_TITULO) Of oBrowse
	Add Column oColumn3  DATA { || If(__LANGUAGE == "SPANISH",ZC5SX3->X3_DESCSPA,If(__LANGUAGE == "ENGLISH",ZC5SX3->X3_DESCENG,ZC5SX3->X3_DESCRIC)) } Title "Descrição" Size Len(ZC5SX3->X3_DESCRIC) Of oBrowse

	If !Empty(cFiltro)
		oBrowse:SetFilterDefault(cFiltro)
	EndIf
	oBrowse:Activate()

	Define SButton oBtnOK From 002, 002 Type 1 Enable Of oPanelBtn OnStop "Ok <Ctrl-O>" Action (lRet := .T., oDlg:End())
	Define SButton oBtnCan From 002, 032 Type 2 Enable Of oPanelBtn OnStop "Cancelar <Ctrl-X>" Action (lRet := .F., oDlg:End())

Activate MsDialog oDlg Centered

ZC5SX3->( dbClearFilter() )

RestArea( aArea )

Return lRet
