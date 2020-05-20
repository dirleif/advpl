#include 'totvs.ch'
#include 'protheus.ch'
//-------------------------------------------------------------------
/*/{Protheus.doc} ACOM010
Importação dados arquivo CSV
@description Rotina para importar dados de arquivo padrão csv de PO para gerar Pedido de Compra

@author		Dirlei@afsouza
@since		10/01/2019
@version	P12

@return 	Nil, nenhum

@type function
/*/
//-------------------------------------------------------------------
user function ACOM010(oGetDados)

local cFileTmp := CGetFile('Arquivos CSV|*.csv',"Selecione Arquivo",0,,.T.,GETF_LOCALHARD,.T.)

private nHandle := 0
private nLast   := 0

// Abre o arquivo
nHandle := FT_FUse(cFileTmp)

// Se houver erro de abertura abandona processamento
if nHandle == -1
    MsgAlert("O arquivo "+ cFileTmp +" não pode ser aberto!","Atenção")
    return
endif

// Posiciona na primeria linha
FT_FGoTop()

// Retorna o número de linhas do arquivo
nLast := FT_FLastRec()

Processa( {|| fImpArq()}, "Aguarde... Importando dados." )
	
return


//-------------------------------------------------------------------
/*/{Protheus.doc} fImpArq
Importa arquivo padrão csv

@author		Dirlei@afsouza
@since		10/01/2019  
@version 	P12

@return		Nil, nenhum

@type		function
/*/
//-------------------------------------------------------------------
static function fImpArq()  

local cLinha := ""
local aLinha := {}
local aItens := {}

// Pula linhas cabeçalho planilha
FT_FSKIP(23)

ProcRegua(0)
while !FT_FEOF()
	
	IncProc("Verificando arquivo ...")
	// Retorna a linha corrente
    cLinha := FT_FReadLn()
    
    aLinha := Separa(cLinha,';')
    if val(aLinha[1]) > 0   
    	aadd(aItens, aLinha)
    endif
        
    // Pula para próxima linha
    FT_FSKIP()
enddo

// Fecha o Arquivo
FT_FUSE()

if !empty(aItens)
	Processa( {|| fProcessa(aItens)}, "Gerando Pedido de Compra... Aguarde" )
	
endif

return	


//-------------------------------------------------------------------
/*/{Protheus.doc} fProcessa
Grava informações no aCols do Pedido Compra

@author		Dirlei@afsouza
@since		10/01/2019
@version 	P12

@param		aITens, array, dados da importação

@return 	Nil, nenhum

@type		function
/*/
//-------------------------------------------------------------------
static function fProcessa(aItens)   

local aArea    := GetArea()
local aAreaSC7 := SC7->(GetArea())
local nI       := 0
local aParam   := {}
local cFornece := Space(TamSX3('A2_COD')[1])
local cLoja    := Space(TamSX3('A2_LOJA')[1])
local cCondPag := Space(TamSX3('C7_COND')[1])
local cContato := Space(TamSX3('C7_CONTATO')[1])
local nMoeda   := 1
local nTxMoeda := 0
local cTes     := Space(TamSX3('F4_CODIGO')[1])
local dEntrega := dDataBase
local cIdPo    := Space(TamSX3('C7_XCODFOR')[1])
local aRetorno := {}
local aCabecPC := {}
local aItensPC := {}
local aLinha   := {}
local cNumPC   := GetNumSC7()
local cProduto := ''
local cDescPro := ''
local cUM      := ''
local cLocal   := ''
local cQuant   := '' // tratar ponto/virgula
local cPreco   := '' // tratar ponto/virgula
local nQuant   := 0
local nPreco   := 0
local nTotal   := 0

private lMsHelpAuto := .t.
private lMsErroAuto := .f.

// tipo, descricao, inicializador, picture, validacao, F3,when, obrigatorio
aadd(aParam,{1,'Fornecedor' ,cFornece,PesqPict('SA2','A2_COD')    ,'.t.','FOR','.t.',20,.t.}) //1
aadd(aParam,{1,"Loja"       ,cLoja   ,PesqPict('SA2','A2_LOJA')   ,'.t.',''   ,'.t.',10,.t.}) //2
aadd(aParam,{1,"Cond. Pagto",cCondPag,PesqPict('SC7','C7_COND')   ,'NaoVazio().And.ExistCpo("SE4")','SE4','.t.',10,.t.}) //3
aadd(aParam,{1,"Contato"    ,cContato,PesqPict('SC7','C7_CONTATO'),'.t.',''   ,'.t.',50,.f.}) //4
aadd(aParam,{1,"Moeda"      ,nMoeda  ,PesqPict('SC7','C7_MOEDA')  ,'.t.',''   ,'.t.',10,.t.}) //5
aadd(aParam,{1,"Taxa"       ,nTxMoeda,PesqPict('SC7','C7_TXMOEDA'),'.t.',''   ,'.t.',50,.f.}) //6
aadd(aParam,{1,'TES'        ,cTes    ,PesqPict('SF4','F4_CODIGO') ,'Vazio().Or.ExistCpo("SF4")','SF4','.t.',10,.t.}) //7
aadd(aParam,{1,"Entrega"    ,dEntrega,"@R 99/99/9999"             ,'.t.',''   ,'.t.',50,.f.}) //8
aadd(aParam,{1,"Id PO"      ,cIdPo   ,PesqPict('SC7','C7_XCODFOR'),'.t.',''   ,'.t.',50,.f.}) //9

If !ParamBox(aParam ,"Dados Pedido Compra",aRetorno)
	Return
EndIf

ProcRegua(0)
aadd(aCabecPC,{"C7_NUM"    ,cNumPC})
aadd(aCabecPC,{"C7_EMISSAO",dDataBase})
aadd(aCabecPC,{"C7_FORNECE",aRetorno[1]})
aadd(aCabecPC,{"C7_LOJA"   ,aRetorno[2]})
aadd(aCabecPC,{"C7_COND"   ,aRetorno[3]})
aadd(aCabecPC,{"C7_CONTATO",aRetorno[4]})
aadd(aCabecPC,{"C7_FILENT" ,xFilial('SC7')})
aadd(aCabecPC,{"C7_MOEDA"  ,aRetorno[5]})
aadd(aCabecPC,{"C7_TXMOEDA",aRetorno[6]})

for nI := 1 to len(aItens)

	IncProc("Gerando Pedido de Compra... Aguarde")
	// retira ponto
	cQuant := strtran(aItens[nI][12],'.')
	cPreco := strtran(aItens[nI][14],'.')
	// substitui virgula por ponto
	cQuant := strtran(cQuant,',','.')
	cPreco := strtran(cPreco,',','.')
	
	cProduto := alltrim(aItens[nI][2])
	//cDescPro := Posicione('SB1',1,xFilial('SB1') + cProduto,'B1_DESC')
	//cUM      := Posicione('SB1',1,xFilial('SB1') + cProduto,'B1_UM')
	//cLocal   := Posicione('SB1',1,xFilial('SB1') + cProduto,'B1_LOCPAD')
	nQuant   := Val(cQuant)
	nPreco   := Val(cPreco)
	nTotal   := nQuant * nPreco

	aadd(aLinha,{"C7_PRODUTO",cProduto   ,nil})
	aadd(aLinha,{"C7_QUANT"  ,nQuant     ,nil})
	aadd(aLinha,{"C7_PRECO"  ,nPreco     ,nil})
	aadd(aLinha,{"C7_TOTAL"  ,nTotal     ,nil})
	aadd(aLinha,{"C7_TES"    ,aRetorno[7],nil})
	aadd(aLinha,{"C7_DATPRF" ,aRetorno[8],nil})
	aadd(aLinha,{'C7_XCODFOR',aRetorno[9],nil})
	aadd(aItensPC,aLinha)
	aLinha := {}	
next 

lMsErroAuto := .f.
 
MsExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCabecPC,aItensPC,3,.F.) //Inclusão

if lMsErroAuto 
	MostraErro()
else
	nRecno := Recno()
	SC7->(dbGoTo(nRecno))
	MsgInfo("Foram importados "+ AllTrim(Str(Len(aItens))) +" item(ns).","Importação PO")
	if MsgYesNo('Deseja abrir o Pedido de Compra '+ cNumPC +'?','Importação PO')
		MATA120(1,/*aCabec*/,/*aItens*/,4,.T.)
		RestArea(aAreaSC7)
		RestArea(aArea)
	endif
endif

return
