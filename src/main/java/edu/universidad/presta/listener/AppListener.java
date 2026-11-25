package edu.universidad.presta.listener;

import edu.universidad.presta.config.AppConfig;
import edu.universidad.presta.config.Conexion;
import edu.universidad.presta.config.Database;
import edu.universidad.presta.dao.OficinaDao;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Enumeration;

/** Al arrancar: prepara la base de datos (crea esquema si hace falta). Al detenerse: libera el driver JDBC. */
@WebListener
public class AppListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        sce.getServletContext().setAttribute("siteName", AppConfig.SITE_NAME);
        Database.init();
        OficinaDao.sembrarSiVacia();
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        Conexion.cerrar();
        ClassLoader cl = getClass().getClassLoader();
        Enumeration<Driver> drivers = DriverManager.getDrivers();
        while (drivers.hasMoreElements()) {
            Driver d = drivers.nextElement();
            if (d.getClass().getClassLoader() == cl) {
                try {
                    DriverManager.deregisterDriver(d);
                } catch (SQLException ignorada) {
                    // sin consecuencias al apagar
                }
            }
        }
    }
}
