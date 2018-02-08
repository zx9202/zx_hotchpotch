这个例子规范了QMainWindow和QDialog和QWidget书写UI的方式。  
通用方式为:  
```C++
void MyQtUI::createUi()
{
    QWidget* mainWidget = this;
    if (dynamic_cast<QDialog*>(this) == nullptr)
    {
        mainWidget = new QWidget(this);
    }

    QGridLayout* mainLayout = new QGridLayout(mainWidget);
    {
        int row = 3, col = 5;
        for (int r = 0; r < row; ++r)
        {
            for (int c = 0; c < col; ++c)
            {
                QString text;
                text.sprintf("r=%d,c=%d", r, c);
                QPushButton* btn = new QPushButton(text, mainWidget);
                btn->setSizePolicy(QSizePolicy::Policy::Minimum, QSizePolicy::Policy::Minimum);
                mainLayout->addWidget(btn, r, c);
            }
        }
    }
    mainWidget->setLayout(mainLayout);

    if (dynamic_cast<QMainWindow*>(this) != nullptr)
    {
        setCentralWidget(mainWidget);
    }
    else if (this != mainWidget)
    {
        this->setWidget(mainWidget);
    }
}
```
