# Conditional Access
This project is to establish a baseline "Best Practice" for Enntra ID. To Secure access to the Tenant.
IT can be run on an exisiting tenant ot a newly created tenant.
Please run with caution as it will do the following:

1. Ask if you have Break Glass/Emergency Access accounts already. If not it will create these and Assign a 16 character randomly generated password.
2. Ask if you have groups you wish to assign the new policies to initally or create 3 new groups with custom names or a templated names within the script.
3. Group1 is for General Users with Entra ID P1 Licenses
4. Group2 is for VIP Users with Entra ID P2 Licenses and will take advantage of the User Risk and Sign-in Risk policies
5. Group3 is a Dynamic Group targeted at roles with privileged access. It is assumed that these start with admin_ and based on this added to the group.
6. Add the 2 Break Glass/Emergency Access accounts as Owners to each group
7. Add the 2 Break Glass/Emergency Access accounts to the Global Administrators role.
8. Create 4 Types of Policies:
9.    PolicyType1 - Targeted at users with the Entra ID P1 licenses. Policies will start with 101, 102, respectively
10.   PolicyType2 - Targeted at VIP users with the Entra ID P2 License. Polciies will start with 201, 202 respectively
11. PolicyType3 - Targeted at both users and VIP users. Policies will start with 301, 302 respectively
12. PolicyType4 - Targeted at the users with Privileged Access, Admins etc. These Policies will start with 901, 902 respectively.
13. Both newly created or existing Break Glass/Emergency Access accounts will be added as excluded to all newly created policies 
   
# How to use the script
Download all files to a local folder. Run the SetupCAPolicies.ps1 file and that will do all the magic

If you have your ownset of policies you wish to use run the Export-Policies.ps1 script. this will connect to your tenant and export all your policies to JSON files in a specified folder. You can then use this to create your own policies in another tenant.

The script turnon-adminconsent.ps1 is still a work in progress, the idea is to prevent the users from consenting to adding apps. it will send the request to an admin instead.
