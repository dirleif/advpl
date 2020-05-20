#include "totvs.ch"
//------------------------------------------------------------------------------
/*/{Protheus.doc} NavegWeb
Criando um navegado web.

@author 	Dirlei Friedrich

@return 	Nil, nenhum

@see        https://tdn.totvs.com/display/tec/TWebEngine
@type 		function
/*/
//------------------------------------------------------------------------------
User Function NavegWeb()

Local cHome  := 'https://www.nfe.fazenda.gov.br' // página inicial 
Local aSize  := MsAdvSize() // função que devolve o tamanho da dialog

// prepara o conector WebSocket
Private oWebChannel := TWebChannel():New()
Private nPort       := oWebChannel::connect()
Private oWebEngine  := Nil

Define Dialog oDlg Title 'Navegador Web Protheus' From aSize[7],000 To aSize[6],aSize[5] of oMainWnd Pixel

    // Cria componente
    oWebEngine := TWebEngine():New(oDlg,000,000,100,100,, nPort)
    oWebEngine:bLoadFinished := {|self,url| ConOut("Termino da carga do pagina: "+ url) }
    oWebEngine:navigate(cHome)
    oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
	
	TButton():New( 005,010, "Voltar" , oDlg,{|| oWebEngine:goBack() },040,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005,050, "Avançar", oDlg,{|| oWebEngine:goForward() },040,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	TButton():New( 005,100, "Home"   , oDlg,{|| oWebEngine:GoHome() },040,010,,,.F.,.T.,.F.,,.F.,,,.F. )
	
Activate Dialog oDlg Centered

Return
