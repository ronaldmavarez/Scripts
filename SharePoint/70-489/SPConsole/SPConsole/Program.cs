using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.SharePoint;
using Microsoft.SharePoint.Publishing;

namespace SPConsole
{
    class Program
    {
        static void Main(string[] args)
        {
            //SPSite oSite = new SPSite("http://svg-ronald/");
            //SPWeb oWeb = oSite.OpenWeb();

            //SPRoleDefinition oRD = new SPRoleDefinition();
            //oRD.Name = "CustomRole";
            //oRD.Description = "I am the role description";

            //oWeb.RoleDefinitions.Add(oRD);
            //oWeb.Update();

            CrossListQueryCacheCode.Testing("http://svg-ronald");
            

        }

        static void testing2()
        {
            CrossListQueryInfo cLQI = new CrossListQueryInfo();
            CrossListQueryCache cLQC = new CrossListQueryCache(cLQI);

            
            //cLQC.GetSiteData()
        }
    }

     
}
