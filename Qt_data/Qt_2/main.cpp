#include<QVariant>
#include <QCoreApplication>

#include <map>
#include <set>
#include <vector>

class MyDataType
{
public:
    std::vector<double> m_field1;
    std::list<float> m_field2;
    std::set<std::string> m_field3;
    std::map<std::string, std::set<int>> m_field4;
    QVariant m_field5;
};
Q_DECLARE_METATYPE(MyDataType);

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    QVariant qVariant;
    MyDataType data1;
    {
        data1.m_field4["test"] = { 3,6,9 };
    }
    qVariant.setValue(data1);
    if (qVariant.canConvert<MyDataType>() == true)
    {
        auto data2 = qVariant.value<MyDataType>();
        printf("");
    }
    if (true)
    {
        QVariant qVariant = qVariantFromValue(data1);
        auto data3 = qvariant_cast<MyDataType>(qVariant);
        printf("");
    }

    return a.exec();
}
