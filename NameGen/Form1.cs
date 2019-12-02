using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Windows.Forms;
using log4net;

namespace NameGen
{
    public partial class Form1 : Form
    {
        private static ILog m_log = LogManager.GetLogger((typeof(Form1)));
        private CLInterface m_luaInterface;
        private CLuaLog m_luaLog;
        private List<String> m_tables;

        public Form1()
        {
            InitializeComponent();
            try
            {
                m_luaInterface = new CLInterface();
                m_luaLog = new CLuaLog();
                m_luaInterface.RegisterObject("csLog", m_luaLog);
            }
            catch (Exception ex)
            {
                m_log.Error("Unable to start the Lua Interface.", ex);
                Application.Exit();
            }
            m_tables = new List<String>();
        }

        private void Form1_Shown(object sender, EventArgs e)
        {
            String localPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            m_log.Info("Loading main scripts...");
            Queue<String> mainscripts = new Queue<String>();
            mainscripts.Enqueue(localPath + "\\utilities.lua");
            while (mainscripts.Count > 0)
            {
                String file = mainscripts.Dequeue();
                m_log.Info(String.Format("Loading {0}...", file));
                m_luaInterface.LoadScript(file);
            }
            List<String> baseList = m_luaInterface.GetTables();

            String scriptPath = localPath + "\\scripts";
            m_log.Info(String.Format("Loading scripts from {0}", scriptPath));
            try
            {
                String[] files = Directory.GetFiles(scriptPath, "*.lua");
                foreach (String file in files)
                {
                    m_log.Info(String.Format("Loading {0}...", file));
                    m_luaInterface.LoadScript(file);
                }
            }
            catch (Exception ex)
            {
                m_log.Error("Unable to load the scripts folder.", ex);
                Application.Exit();
            }
            List<String> fullList = m_luaInterface.GetTables();
            foreach(String tbl in fullList)
            {
                bool found = false;
                foreach(String t in baseList)
                {
                    if(t.Equals(tbl))
                    {
                        found = true;
                        break;
                    }
                }
                if (!found)
                    m_tables.Add(tbl);
            }
            foreach (String t in m_tables)
                cbxGenMethod.Items.Add(t);
            cbxGenMethod.SelectedIndex = 0;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if(!Directory.Exists("Lists"))
            {
                try
                {
                    Directory.CreateDirectory("Lists");
                }
                catch(Exception ex)
                {
                    m_log.Error("Unable to create directory:", ex);
                    return;
                }
                String[] files = Directory.GetFiles(".\\Lists", "*.txt");
                int index = 1;
                if(files.Length > 0)
                {
                    foreach (String file in files)
                    {
                        String[] parts = file.Split('_');
                        if (parts.Length < 2)
                            continue;
                        String[] subparts = parts[1].Split('.');
                        try
                        {
                            int filenum = int.Parse(subparts[0]);
                            if (filenum > index)
                                index = filenum;
                        }
                        catch(Exception ex)
                        {
                            continue;
                        }
                    }
                }
                String method = cbxGenMethod.Text + ".GetName";
                List<String> names = new List<String>();
                for(int i = 0; i < (int)nudGenCount.Value; ++i)
                {
                    object[] res = m_luaInterface.Call(method, null);
                    names.Add((String)res[0]);
                }
                String outfile = String.Format(".\\Lists\\namelist_{0}.txt", index);
                using (StreamWriter sw = new StreamWriter(outfile))
                {
                    foreach (String name in names)
                        sw.WriteLine(name);
                }
            }
        }

        private void btnGenerate_Click(object sender, EventArgs e)
        {
            String method = cbxGenMethod.Text + ".GetName";
            object[] res = m_luaInterface.Call(method, null);
            tbxName.Text = (String)res[0];
        }
    }
}
