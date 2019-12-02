using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using log4net;

namespace NameGen
{
    class CLuaLog
    {
        private static ILog m_log = LogManager.GetLogger((typeof(CLuaLog)));

        public void LogInfo(String script, String message)
        {
            String msg = String.Format("{0} : {1}", script, message);
            m_log.Info(msg);
        }

        public void LogWarn(String script, String message)
        {
            String msg = String.Format("{0} : {1}", script, message);
            m_log.Warn(msg);
        }

        public void LogError(String script, String message)
        {
            String msg = String.Format("{0} : {1}", script, message);
            m_log.Error(msg);
        }

    }
}
