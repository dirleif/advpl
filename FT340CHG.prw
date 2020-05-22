//------------------------------------------------------------------------------
/*/{Protheus.doc} FT340CHG
PE utilizado para alterar o nome do arquivo durante a gravação no banco de conhecimento.

@author 	Dirlei Friedrich

@return     cNameServ, novo nome arquivo

@see        https://tdn.totvs.com/pages/releaseview.action?pageId=6784480
@type 		function
/*/
//------------------------------------------------------------------------------
User Function FT340CHG()

Local cNameServ	:= ParamIxb[1]
Local cTitulo   := "Informe a Posição da FOTO"
Local aItens    := {"Frente","Traseira","Lateral_1","Lateral_2"}
Local nRadio    := 1
Local nOpc      := 0
Local nTop      := oMainWnd:nTop + 35
Local nLeft     := oMainWnd:nLeft + 10
Local nBottom   := oMainWnd:nBottom - 12
Local nRight    := oMainWnd:nRight - 10
Local nTopScr   := 0
Local nLefScr   := 0
Local nBotScr   := 0
Local nRigScr   := 0
Local cFileRMT  := ""
Local cFilePNG  := ""
Local cExtensao := ""
Local oFont     := TFont():New("Arial",0,-12,,.T.,,,,,.F.,.F.)
Local cPathSrv  := MsDocPath()
Local cPathCli  := "" 
Local lCompacta := .F.
Local lOk       := .F.
                                                                              
Static oDrawer := Nil

If AllTrim(FunName()) == "LAUDO" // Se for a inclusão de fotos do laudo técnico muda o arquivo de JPG para PNG
     
	Define MSDialog oDlgImg Title cTitulo Of oMainWnd Pixel From nTop,nLeft To nBottom,nRight STYLE DS_MODALFRAME
	
	nTopScr := oDlgImg:nTop - 30
	nLefScr := oDlgImg:nLeft + 40
	nBotScr := oDlgImg:nBottom - 35 
	nRigScr := oDlgImg:nRight - 15
	
	oRadio := TRadMenu():New(010,010,aItens,,oDlgImg,,,,,,,,100,12,,,,.T.)
	oRadio:bSetGet := {|u|Iif(PCount()==0,nRadio,nRadio:=u)}
	
	oTScrollBox := TScrollBox():New(oDlgImg,015,050,250,710,.T.,.T.,.T.)
	oDrawer     := tDrawer():New(0,0,oTScrollBox,300,300)
	cFileRmt    := __cWizard

	If File(cFileRMT)
		oDrawer:OpenImage(cFileRMT)
	EndIf                                                                    
   
	cNumOS  := AB6->AB6_NUMOS
	cSelo   := Iif(!Empty(AB6->AB6_ETIQUE),AllTrim(AB6->AB6_ETIQUE),AllTrim(AB6->AB6_NUMSER))
	cTxtJpg := cNumOS +"-"+ cSelo
	oDrawer:AddText(010,010,cTxtJpg)
	   
	cFilePNG  := SubStr(cFileRMT,1,At(".",cFileRMT)) +"png"
	cExtensao := AllTrim(SubStr(cFileRMT,At(".",cFileRMT)))
	//cPathCli  := AllTrim(SubStr(cFilePNG,1,RAt("\",cFilePNG)))
	
	oSayImg    := TSay():New(005,050,{|| cFileRMT },oDlgImg,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,100,15)
	oBtnGrv    := TButton():New(050,005, "Grava PNG" ,oDlgImg, {|| MsgRun("Processando... Aguarde","Convertendo imagem",{|| /*Converte(cFilePNG,Nil)*/ oDrawer:SaveImage(cFilePNG,"PNG") }) },40,12,,,,.T.,,,, { || !File(cFilePNG) },,)
	oBtnOk     := TButton():New(065,005, "Ok"        ,oDlgImg, {|| nOpc := 1, oDlgImg:End() },40,12,,,,.T.,,,, { || nRadio > 0 .And. File(cFilePNG) },,)
	oBtnCancel := TButton():New(080,005, "Cancelar"  ,oDlgImg, {|| cNameServ := "", oDlgImg:End() },40,12,,,,.T.,,,, { || .T. },,)
   
	Activate MSDialog oDlgImg Centered

	If nOpc == 1                              
		cPosicao  := Lower(aItens[nRadio])
		cNovoNome := cNumOS +"-"+ cSelo +"-"+ cPosicao
		cNameServ := cNovoNome + Lower(cExtensao)

		// Redimensionar imagem e copiar Server
		MsgRun("Processando... Aguarde.","Redimensionar Imagem",{|| Converte(cFilePNG,cNovoNome) })

	EndIf

EndIf

Return (cNameServ)


//------------------------------------------------------------------------------
/*/{Protheus.doc} Converte
Função para converter redimensionar imagem

@author 	Dirlei Friedrich

@param      cImgPNG, caracter, nome do arquivo original
            cArquivo, caracter, nome do arquivo convertido

@return     cNameServ, novo nome arquivo

@obs        é necessário o download do imagemagick e sua instalação na estação
            que realiza o processo de converter a imagem.
@see        https://imagemagick.org
@type 		function
/*/
//------------------------------------------------------------------------------
Static Function Converte(cImgPNG,cArquivo)

Local cDirEmp   := "co"+ AllTrim(cEmpAnt)
Local cPathSrv  := "\opt\protheus\protheus_data\dirdoc\"+ cDirEmp +"\shared"
Local cPathCli  := AllTrim(SubStr(cImgPNG,1,RAt("\",cImgPNG))) 
Local cArqCli   := cPathCli + cArquivo +".png"
Local cResize   := "600x600"
Local cComando  := "convert.exe -resize "+ cResize +" "+ cImgPNG +" "+ cArqCli
Local lCompacta := .F.
Local lOk       := .F.

// Gravar imagem PNG
// não foi utilizada esta conversão pois o servidor Protheus era Linux
//oDrawer:SaveImage(cImgPNG,"PNG") 

// Redimensiona imagem
WaitRun(cComando,0)

MsgInfo("Imagem redimensionada no formato PNG","Imagem PNG")

// Copia imagem para Server
MsgRun("Copiando arquivo para o Servidor... Aguarde.","Cópia Arquivo",{|| lOk := CpyT2S(cArqCli,cPathSrv,lCompacta) })

If lOk
	MsgInfo("Cópia da imagem efetuada com sucesso para o servidor!","Cópia Servidor")
Else
	MsgInfo("Ocorreu falha na cópia da imagem!","Cópia Servidor")
EndIf

Return
