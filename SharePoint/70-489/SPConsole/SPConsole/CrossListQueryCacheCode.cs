using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SharePoint.Publishing;
using Microsoft.SharePoint.Publishing.WebControls;
using Microsoft.SharePoint;
using System.Web;

namespace SPConsole
{
    class CrossListQueryCacheCode
    {
        //GetSiteDataResults(Microsoft.SharePoint.SPSite,System.Boolean)
        // Returns the results of the current query on the specified site.  The query will be run against
        // an SPList if useSpQueryOnList is set to true.  Otherwise the query will be run against a site or web

        // This version of GetSiteDataResults uses the web url in this object's CrossListQueryInfo to determine
        // either the web to query against or the web of the list being queried against depending on the value
        // of useSpQueryOnList.
        public static void Testing(string siteURL) {

            SPSite oSite = new SPSite(siteURL);
            SPWeb oWeb = oSite.RootWeb;

            string query = string.Empty;
            string websQuery = string.Format("<Webs Scope=\"{0}\"/>", "None");
            string lists = "<Lists ServerTemplate=\"101\"" + " ><List ID=\"4db0e78c-dd9c-45f2-8b9c-e5f602e7d0b7\" /></Lists>";
            bool useList = true;
            //string relativeUrl = this.GetRelativeUrl();
            //query = string.Format("<Where><Eq><FieldRef Name='FSObjType' /><Value Type='LookUp'>1</Value></Eq></Where>", relativeUrl);

            CrossListQueryInfo info = new CrossListQueryInfo();
            info.Lists = lists;
            info.Webs = websQuery;
            info.Query = query;
            info.ViewFields = "<FieldRef Name=\"FileLeafRef\"/>";
            info.WebUrl = oWeb.ServerRelativeUrl;
            CrossListQueryCache cache = new CrossListQueryCache(info);
            SiteDataResults sd = cache.GetSiteDataResults(oSite, true);
        }

        public static void ExampleOne(string siteURL)
        {
            using (SPSite site = new SPSite(siteURL))
            {
                //Get a CbqQueryVersionInfo object from a ContentByQueryWebPart and use it to get a CrossListQueryInfo
                ContentByQueryWebPart cbq = new ContentByQueryWebPart();
                CbqQueryVersionInfo versionInfo = cbq.BuildCbqQueryVersionInfo();
                CrossListQueryInfo queryInfo = versionInfo.VersionCrossListQueryInfo;
                // Create a new CrossListQueryCache object with the queryInfo we just got
                CrossListQueryCache crossListCache = new CrossListQueryCache(queryInfo);

                SiteDataResults results = crossListCache.GetSiteDataResults(site, false);

                
            }
        }

        private static CrossListQueryInfo EmployeeCrossListQueryInfo()

        {

            CrossListQueryInfo clqi = new CrossListQueryInfo();

            // Insert the list types that you want to use. In this case, its the publishing page library (850, see code below)
            clqi.Lists = "<Lists ServerTemplate=\"100\" />"; 

            // Insert the field2s that you want to see. If there is a field inside that doesnt exist in the list that you query, your result will be nill, nada, nothing.
            // Make sure that you put in the INTERNAL field names!
            clqi.ViewFields = "<FieldRef Name=\"Last_x0020_Name\" /><FieldRef Name=\"First_x0020_Name\" /><FieldRef Name=\"Address\" /><FieldRef Name=\"Phone_x0020_Number\" />";

            // scop to use. Another possibility is SiteCollection
            clqi.Webs = "<Webs Scope=\"Recursive\" />";
            
            // turn the cache on
            clqi.UseCache = true;

            // if row limit == 0, you will get 0 results
            clqi.RowLimit = 100;

            // I know a stringbuilder would be better, but i wanted to show the markup of the query
            clqi.Query = "<OrderBy><FieldRef Name='ID' /></OrderBy>"; 

            // put the CrossListQueryInfo object into the CrossListQueryCache
            //CrossListQueryCache clqc = new CrossListQueryCache(clqi); 

            // and query the data!
            // make sure: the GetSiteData(SPWeb web) and GetSiteData(SPWeb web, SPSiteDataQuery query) DO NOT use caching!!!
            //DataTable tbl = clqc.GetSiteData(SPContext.Current.Site, CrossListQueryCache.ContextUrl());

            // return the datatable

            return clqi;

        }
    }
}
