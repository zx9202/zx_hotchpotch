#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QDockWidget>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

public:
    void createUi();

private Q_SLOTS:
    void slotClicked4dialog(bool b);
    void slotClicked4widget();
    void slotClicked4mainWindow();

private:
    QList<QDockWidget*> m_dockWidgets;
};

#endif // MAINWINDOW_H
