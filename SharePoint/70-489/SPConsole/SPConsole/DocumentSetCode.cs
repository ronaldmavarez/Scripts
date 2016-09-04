using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SharePoint;
using System.Collections;
using Microsoft.Office.DocumentManagement.DocumentSets;

namespace SPConsole
{
     class DocumentSetCode{
        static void main(){
            using (SPSite oSite = new SPSite("http://servername")){
                SPWeb oWeb = oSite.OpenWeb();
                SPList oList = oWeb.Lists["listName"];

                SPFolder oFolder = oList.RootFolder;
                SPContentType oContentType = oList.ContentTypes["DocumentSetCT"];

                Hashtable properties = new Hashtable();
                properties.Add("PropertyName1", "PropertyValue1");
                properties.Add("PropertyName2", "PropertyValue2");
                properties.Add("PropertyName3", "PropertyValue3");
                properties.Add("PropertyName4", "PropertyValue4");

                var oDocSet = DocumentSet.Create(oFolder, "First Document Set", oContentType.Id, properties);
            }
        }
    }
}
