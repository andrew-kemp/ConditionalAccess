# Conditional Access
This project is to establish a baseline "Best Practice" for Enntra ID. To Secure access to the Tenant.
IT can be run on an exisiting tenant ot a newly created tenant.
Please run with caution as it will do the following:

1. Ask if you have Break Glass/Emergency Access accounts already. If not it will create these and Assign a 16 character randomly generated password.
2. Ask if you have groups you wish to assign the new policies to initally or create 3 new groups with custom names or a templated names within the script.
   a. Group1 is for General Users with Entra ID P1 Licenses
   b. Group2 is for VIP Users with Entra ID P2 Licenses and will take advantage of the User Risk and Sign-in Risk policies
   c. Group3 is a Dynamic Group targeted at roles with privileged access. It is assumed that these start with admin_ and based on this added to the group.
4. Add the 2 Break Glass/Emergency Access accounts as Owners to each group
5. Add the 2 Break Glass/Emergency Access accounts to the Global Administrators role.
6. Create 4 Types of Policies:
   PolicyType1 - Targeted at users with the Entra ID P1 licenses. Policies will start with 101, 102, respectively
   PolicyType2 - Targeted at VIP users with the Entra ID P2 License. Polciies will start with 201, 202 respectively
   PolicyType3 - Targeted at both users and VIP users. Policies will start with 301, 302 respectively
   PolicyType4 - Targeted at the users with Privileged Access, Admins etc. These Policies will start with 901, 902 respectively.
7. Both newly created or existing Break Glass/Emergency Access accounts will be added as excluded to all newly created policies 
   
