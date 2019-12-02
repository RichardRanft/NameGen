using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Text;
using System.IO;
using System.Reflection;
using LuaInterface;
using log4net;

namespace NameGen
{
    public class CLInterface
    {
        private static ILog m_log = LogManager.GetLogger((typeof(CLInterface)));

        private Lua m_lua;
        private CLockObj m_lock;

        private List<String> m_gtableEntries;

        public object this[String key]
        {
            get
            {
                try
                {
                    lock (m_lock)
                        return m_lua[key];
                }
                catch (NullReferenceException ex)
                {
                    m_log.Error(String.Format("{0} isn't loaded.", key), ex);
                    return null;
                }
                catch (LuaException ex)
                {
                    m_log.Error(String.Format("Caught a Lua exception in: {0}", key), ex);
                    return null;
                }
            }
            set
            {
                lock (m_lock)
                    m_lua[key] = value;
            }
        }

        public CLInterface()
        {
            m_lua = new Lua();
            m_lock = new CLockObj();
            m_gtableEntries = new List<String>();
        }

        public void LoadScript(String path)
        {
            try
            {
                lock (m_lock)
                {
                    m_lua.DoFile(path);
                    LuaTable tbl = m_lua.GetTable("_G");
                    m_gtableEntries.Add(path);
                    foreach (DictionaryEntry entry in tbl)
                    {
                        String etype = entry.Value.GetType().ToString();
                        m_gtableEntries.Add(String.Format("{0} : {1}", etype.PadRight(25, ' '), entry.Key.ToString()));
                    }
                }
            }
            catch(Exception ex)
            {
                m_log.Error(String.Format("Error accessing path {0}", path), ex);
            }
        }

        public object[] Call(String fname, object[] args)
        {
            try
            {
                lock (m_lock)
                {
                    if (args == null)
                        args = new object[] { };
                    if (m_lua[fname] != null)
                    {
                        LuaFunction func = m_lua[fname] as LuaFunction;
                        object[] res = func.Call(args);
                        return res;
                    }
                    else
                        m_log.Info(String.Format("The Lua function {0} isn't loaded.", fname));
                }
            }
            catch(NullReferenceException ex)
            {
                m_log.Error(String.Format("The Lua function {0} isn't loaded.", fname), ex);
            }
            catch (LuaException ex)
            {
                m_log.Error(String.Format("Caught a Lua exception in: {0}", fname), ex);
            }
            return new object[] { };
        }

        public LuaTable NewTable()
        {
            lock(m_lock)
                return (LuaTable)m_lua.DoString("return {}")[0];
        }

        public object[] DoString(String script)
        {
            lock (m_lock)
                return m_lua.DoString(script);
        }

        public void RegisterTable(String name)
        {
            lock (m_lock)
                m_lua.NewTable(name);
        }

        public void RegisterObject(String tableName, object obj)
        {
            lock (m_lock)
            {
                Type t = obj.GetType();
                MethodInfo[] info = t.GetMethods();
                if (info.Length > 0)
                {
                    RegisterTable(tableName);
                    foreach (MethodInfo i in info)
                    {
                        if (i.Attributes == (MethodAttributes.FamANDAssem | MethodAttributes.Family | MethodAttributes.Virtual | MethodAttributes.HideBySig | MethodAttributes.VtableLayoutMask))
                            continue;
                        if (i.Name == "GetType")
                            continue;
                        String mname = tableName + "." + i.Name;
                        // Pick up and register overloads, since Type.GetMethod() can only return a single value.
                        var paraminfo = i.GetParameters();
                        List<Type> types = new List<Type>();
                        foreach (ParameterInfo pinfo in paraminfo)
                            types.Add(pinfo.ParameterType);
                        m_lua.RegisterFunction(mname, obj, obj.GetType().GetMethod(i.Name, types.ToArray()));
                    }
                }
            }
        }

        public void RegisterMethod(String luaName, object obj, System.Reflection.MethodBase mbase)
        {
            try
            {
                lock(m_lock)
                    m_lua.RegisterFunction(luaName, obj, mbase);
            }
            catch(NullReferenceException ex)
            {
                m_log.Error(String.Format("The Lua function {0} can't be registered.", luaName), ex);
            }
            catch (LuaException ex)
            {
                m_log.Error(String.Format("The Lua function {0} can't be registered.", luaName), ex);
            }
        }

        public List<String> GetTables()
        {
            List<String> tables = new List<String>();
            foreach(String line in m_gtableEntries)
            {
                if(line.Contains(".LuaTable"))
                {
                    String temp = line.Remove(0, line.IndexOf(':') + 2);
                    tables.Add(temp);
                }
            }
            return tables;
        }

        private void dumpTable(List<String> lines)
        {
            try
            {
                using (StreamWriter sw = new StreamWriter("envdump.txt"))
                {
                    foreach (String line in lines)
                        sw.WriteLine(line);
                }
            }
            catch (Exception ex)
            {
                m_log.Error("Unable to dump table.", ex);
            }
        }

        public void DumpGTable()
        {
            dumpTable(m_gtableEntries);
        }
    }
    class CLockObj
    {
        public String Name = "CLockObj";
    }

    public class NoOpSynchronizeInvoke : ISynchronizeInvoke
    {
        private delegate object GeneralDelegate(Delegate method,
                                                object[] args);

        public bool InvokeRequired { get { return false; } }

        public Object Invoke(Delegate method, object[] args)
        {
            return method.DynamicInvoke(args);
        }

        public IAsyncResult BeginInvoke(Delegate method,
                                        object[] args)
        {
            GeneralDelegate x = Invoke;
            return x.BeginInvoke(method, args, null, x);
        }

        public object EndInvoke(IAsyncResult result)
        {
            GeneralDelegate x = (GeneralDelegate)result.AsyncState;
            return x.EndInvoke(result);
        }
    }
}
