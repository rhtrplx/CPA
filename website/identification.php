
<?php
	require_once('C_site.php'); //équivalent à include 
	$mySite = new C_site();


	
	//-------------------------------------------------------------
	if ( (isset($_POST ['pseudo']) && !empty($_POST['pseudo']) ) && (isset($_POST['pass']) && !empty($_POST['pass']) ) )
	{
		$pseudo=$_POST['pseudo'];
		$pass=$_POST['pass'];
		//echo "Identification avec $pseudo et $pass<br />";
		$ErrorCode=$mySite->Authentifier($pseudo,$pass);
		if ($ErrorCode==0)
		{
			echo "Authentification réussie<br />";
			$_SESSION['pseudo'] = $pseudo;
			echo "<meta http-equiv='refresh' content='2'> ";
		}
		else
		{
			echo "<b>Echec d'authentification!</b><br />";
			switch ($ErrorCode)
			{
				case 1: echo "Utilisateur inconnu.<br />"; break;
				case 2: echo "Erreur de mot de passe.<br />"; break;
			}
		}
	}
	else
	{
		$mySite->afficherFormulaireConnexion();
	}
?>
