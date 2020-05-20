#Include 'totvs.ch'
#Include 'protheus.ch'
//-------------------------------------------------------------------
/*/{Protheus.doc} ImportCsv
Importação dados arquivo CSV

@description Rotina para importar dados de arquivo padrão csv para 
gerar Pedido de Compra

@author		Dirlei Friedrich

@return 	Nil, nenhum

@type 		function
/*/
//-------------------------------------------------------------------
User Function ImportCsv(oGetDados)

Local cFileTmp := CGetFile('Arquivos CSV|*.csv',"Selecione Arquivo",0,,.T.,GETF_LOCALHARD,.T.)

Private nHandle := 0
Private nLast   := 0

// Abre o arquivo
nHandle := FT_FUse(cFileTmp)

// Se houver erro de abertura abandona processamento
If nHandle == -1
    MsgAlert("O arquivo "+ cFileTmp +" não pode ser aberto!","Atenção")
    Return
EndIf

// Posiciona na primeria linha
FT_FGoTop()

// Retorna o número de linhas do arquivo
nLast := FT_FLastRec()

Processa( {|| fImpArq()}, "Aguarde... Importando dados." )
	
Return


//-------------------------------------------------------------------
/*/{Protheus.doc} fImpArq
Importa arquivo padrão csv

@author		Dirlei Friedrich

@return		Nil, nenhum

@type		function
/*/
//-------------------------------------------------------------------
Static Function fImpArq()  

Local cLinha := ""
Local aLinha := {}
Local aItens := {}

// Pula linhas cabeçalho planilha
FT_FSKIP(23) // verifique quantas linhas ocupa seu cabeçalho 

ProcRegua(0)
While !FT_FEOF()
	
	IncProc("Verificando arquivo ...")
	// Retorna a linha corrente
    cLinha := FT_FReadLn()
    
    aLinha := Separa(cLinha,';')
    If Val(aLinha[1]) > 0   
    	AAdd(aItens, aLinha)
    EndIf
        
    // Pula para próxima linha
    FT_FSKIP()
EndDo

// Fecha o Arquivo
FT_FUSE()

If !Empty(aItens)
	Processa( {|| fProcessa(aItens)}, "Gerando Pedido de Compra... Aguarde" )
EndIf

Return	


//-------------------------------------------------------------------
/*/{Protheus.doc} fProcessa
Grava informações no aCols do Pedido Compra

@author		Dirlei Friedrich

@param		aItens, array, dados da importação

@return 	Nil, nenhum

@type		function
/*/
//-------------------------------------------------------------------
Static Function fProcessa(aItens)   

Local aArea    := GetArea()
Local aAreaSC7 := SC7->(GetArea())
Local nI       := 0
Local aParam   := {}
Local cFornece := Space(TamSX3('A2_COD')[1])
Local cLoja    := Space(TamSX3('A2_LOJA')[1])
Local cCondPag := Space(TamSX3('C7_COND')[1])
Local cContato := Space(TamSX3('C7_CONTATO')[1])
Local nMoeda   := 1
Local nTxMoeda := 0
Local cTes     := Space(TamSX3('F4_CODIGO')[1])
Local dEntrega := dDataBase
Local cIdPo    := Space(TamSX3('C7_XCODFOR')[1]) //Campo customizado
Local aRetorno := {}
Local aCabecPC := {}
Local aItensPC := {}
Local aLinha   := {}
Local cNumPC   := GetNumSC7()
Local cProduto := ''
Local cDescPro := ''
Local cUM      := ''
Local cLocal   := ''
Local cQuant   := '' // tratar ponto/virgula
Local cPreco   := '' // tratar ponto/virgula
Local nQuant   := 0
Local nPreco   := 0
Local nTotal   := 0

Private lMsHelpAuto := .T.
Private lMsErroAuto := .F.

// tipo, descricao, inicializador, picture, validacao, F3, when, obrigatorio
AAdd(aParam,{1,'Fornecedor' ,cFornece,PesqPict('SA2','A2_COD')    ,'.T.','FOR','.T.',20,.T.}) //1
AAdd(aParam,{1,"Loja"       ,cLoja   ,PesqPict('SA2','A2_LOJA')   ,'.T.',''   ,'.T.',10,.T.}) //2
AAdd(aParam,{1,"Cond. Pagto",cCondPag,PesqPict('SC7','C7_COND')   ,'NaoVazio().And.ExistCpo("SE4")','SE4','.T.',10,.T.}) //3
AAdd(aParam,{1,"Contato"    ,cContato,PesqPict('SC7','C7_CONTATO'),'.T.',''   ,'.T.',50,.T.}) //4
AAdd(aParam,{1,"Moeda"      ,nMoeda  ,PesqPict('SC7','C7_MOEDA')  ,'.T.',''   ,'.T.',10,.T.}) //5
AAdd(aParam,{1,"Taxa"       ,nTxMoeda,PesqPict('SC7','C7_TXMOEDA'),'.T.',''   ,'.T.',50,.T.}) //6
AAdd(aParam,{1,'TES'        ,cTes    ,PesqPict('SF4','F4_CODIGO') ,'Vazio().Or.ExistCpo("SF4")','SF4','.T.',10,.T.}) //7
AAdd(aParam,{1,"Entrega"    ,dEntrega,"@R 99/99/9999"             ,'.T.',''   ,'.T.',50,.T.}) //8
AAdd(aParam,{1,"Id PO"      ,cIdPo   ,PesqPict('SC7','C7_XCODFOR'),'.T.',''   ,'.T.',50,.T.}) //9

If !ParamBox(aParam ,"Dados Pedido Compra",aRetorno)
	Return
EndIf

ProcRegua(0)
AAdd(aCabecPC,{"C7_NUM"    ,cNumPC})
AAdd(aCabecPC,{"C7_EMISSAO",dDataBase})
AAdd(aCabecPC,{"C7_FORNECE",aRetorno[1]})
AAdd(aCabecPC,{"C7_LOJA"   ,aRetorno[2]})
AAdd(aCabecPC,{"C7_COND"   ,aRetorno[3]})
AAdd(aCabecPC,{"C7_CONTATO",aRetorno[4]})
AAdd(aCabecPC,{"C7_FILENT" ,xFilial('SC7')})
AAdd(aCabecPC,{"C7_MOEDA"  ,aRetorno[5]})
AAdd(aCabecPC,{"C7_TXMOEDA",aRetorno[6]})

For nI := 1 To Len(aItens)

	IncProc("Gerando Pedido de Compra... Aguarde")
	// retira ponto
	cQuant := StrTran(aItens[nI][12],'.')
	cPreco := StrTran(aItens[nI][14],'.')
	// substitui virgula por ponto
	cQuant := StrTran(cQuant,',','.')
	cPreco := StrTran(cPreco,',','.')
	
	cProduto := AllTrim(aItens[nI][2])
	// Rotina padrão já preenche!
	//cDescPro := Posicione('SB1',1,xFilial('SB1') + cProduto,'B1_DESC')
	//cUM      := Posicione('SB1',1,xFilial('SB1') + cProduto,'B1_UM')
	//cLocal   := Posicione('SB1',1,xFilial('SB1') + cProduto,'B1_LOCPAD')
	nQuant   := Val(cQuant)
	nPreco   := Val(cPreco)
	nTotal   := nQuant * nPreco

	AAdd(aLinha,{"C7_PRODUTO",cProduto   ,nil})
	AAdd(aLinha,{"C7_QUANT"  ,nQuant     ,nil})
	AAdd(aLinha,{"C7_PRECO"  ,nPreco     ,nil})
	AAdd(aLinha,{"C7_TOTAL"  ,nTotal     ,nil})
	AAdd(aLinha,{"C7_TES"    ,aRetorno[7],nil})
	AAdd(aLinha,{"C7_DATPRF" ,aRetorno[8],nil})
	AAdd(aLinha,{'C7_XCODFOR',aRetorno[9],nil})
	AAdd(aItensPC,aLinha)
	aLinha := {}	
Next 

lMsErroAuto := .F.
 
MSExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCabecPC,aItensPC,3,.F.) //Inclusão

If lMsErroAuto 
	MostraErro()
Else
	nRecno := Recno()
	SC7->(dbGoTo(nRecno))
	MsgInfo("Foram importados "+ AllTrim(Str(Len(aItens))) +" item(ns).","Importação PO")
	If MsgYesNo("Deseja abrir o Pedido de Compra "+ cNumPC +"?","Importação PO")
		MATA120(1,/*aCabec*/,/*aItens*/,4,.T.)
		RestArea(aAreaSC7)
		RestArea(aArea)
	EndIf
EndIf

Return
