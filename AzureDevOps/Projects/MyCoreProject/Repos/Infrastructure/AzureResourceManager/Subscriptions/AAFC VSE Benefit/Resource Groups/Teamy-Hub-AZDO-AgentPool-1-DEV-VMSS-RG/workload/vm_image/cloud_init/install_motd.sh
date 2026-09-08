echo "update_motd.sh begin"
#1.7 Warning Banners#asss
#####################
#1.7.1.1 Ensure message of the day is configured properly (Scored) L1 L1

echo "************************************************************************************************************      
********************************************** W.A.R.N.I.N.G ***********************************************
* THIS EQUIPMENT IS THE PROPERTY OF AGRICULTURE AND AGRI-FOOD CANADA. UNAUTHORIZED USERS WILL BE           *
* PROSECUTED. THE PROGRAMS AND DATA STORED ON THIS SYSTEM ARE LICENSED TO OR ARE PRIVATE PROPERTY OF THE   *
* GOVERNMENT OF CANADA AND ARE LAWFULLY AVAILABLE ONLY TO AUTHORIZED USERS FOR APPROVED PURPOSES.          *
* UNAUTHORIZED ACCESS TO ANY PROGRAM OR DATA ON THIS SYSTEM IS NOT PERMITTED. THIS SYSTEM MAY BE           *
* MONITORED AT ANY TIME FOR OPERATIONAL REASONS.                                                           *
**************************************** A.V.E.R.T.I.S.S.E.M.E.N.T *****************************************
* CET EQUIPEMENT EST LA PROPRIETE DE AGRICULTURE ET AGROALIMENTAIRE CANADA. LES UTILISATEURS NON AUTORISES *
* SERONT POURSUIVIS. LES DONNEES ET LES PROGRAMMES ENREGISTRES DANS CE SYSTEME SONT OCTROYES, EN VERTU     *
* DUNE LICENCE, AU GOUVERNEMENT DU CANADA OU SONT LA PROPRIETE DE CE DERNIER, ET SONT LEGALEMENT MIS A LA  *
* DISPOSITION DES UTILISATEURS AUTORISES POUR DES FINS APPROUVEES. TOUT ACCES NON AUTORISE AUX DONNEES ET  *
* AUX PROGRAMMES CONTENUS DANS CE SYSTEME EST INTERDIT. LE SYSTEME PEUT, EN TOUT TEMPS, FAIRE LOBJET DE    *
* SURVEILLANCE POUR DES MOTIFS DORDRE OPERATIONNEL.                                                        *
************************************************************************************************************" > /etc/motd
egrep '(\\v|\\r|\\m|\\s)' /etc/motd
#1.7.1.2 Ensure local login warning banner is configured properly (Not Scored) L1 L1
echo "**********************************************************************************************************
********************************************************W.A.R.N.I.N.G **************************************
AAFC Authorized uses only. All activity may be monitored and reported.********************************************************
***********************************************************************************************************" > /etc/issue
#1.7.1.3 Ensure remote login warning banner is configured properly (Not Scored) L1 L1
echo "**********************************************************************************************************
********************************************************W.A.R.N.I.N.G **************************************
AAFC Authorized uses only. All activity may be monitored and reported.********************************************************
***********************************************************************************************************" > /etc/issue.net
#1.7.1.4 Ensure permissions on /etc/motd are configured (Not Scored) L1 L1
chown root:root /etc/motd
chmod 644 /etc/motd
#1.7.1.5 Ensure permissions on /etc/issue are configured (Scored) L1 L1
chown root:root /etc/issue
chmod 644 /etc/issue
#1.7.1.6 Ensure permissions on /etc/issue.net are configured (Not Scored) L1 L1
chown root:root /etc/issue.net
chmod 644 /etc/issue.net
echo "update_motd.sh end"
